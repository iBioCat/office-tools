# Importing necessary libraries
from flask import Flask, render_template, session, redirect, url_for, flash, request
from flask_bootstrap import Bootstrap
from flask_wtf import FlaskForm
from wtforms import *
from wtforms.validators import DataRequired
import random
import pyodbc 
import json
from datetime import datetime, timedelta
import logging
import sys
from flask_htmlmin import HTMLMIN

# log_file = 'C:\\inetpub\\wwwroot\\recyclables\\app.log'
# log_file = 'C:\\inetpub\\wwwroot\\recyclables_test\\app.log'
# log_file = 'C:\\PythonProjects\\ClearvVersions\\recyc\\Recyclables\\app.log'
# sys.stdout = open(log_file, "a")
# sys.stderr = open(log_file, "a")

# create a log file
# log_file = 'C:\\PythonProjects\\ClearvVersions\\recyc\\Recyclables\\app.log'

# # set up logging to file - see previous section for more details
# logging.basicConfig(level=logging.DEBUG, filename=log_file, filemode='w')

# # set up logging to console
# console = logging.StreamHandler()
# console.setLevel(logging.INFO)

# # set a format which is simpler for console use
# formatter = logging.Formatter('%(message)s')
# console.setFormatter(formatter)

# # add the handler to the root logger
# logging.getLogger('').addHandler(console)
global last_user
last_user = '???'


Test_Mode = False

admin_roles = ['Администратор','Сотрудник склада вторсырья']
user_roles = ['Начальник ОПС','Пользователь','Сотрудник ОПС']
# admin_roles = ['Начальник ОПС','Пользователь','Сотрудник ОПС']
# user_roles = ['Администратор','Сотрудник склада вторсырья']



# list of all positions 
positions = [   "Дырокол",
                "Нож канцелярский",
                "Маркер",
                "Степлер (24/6, 26/6 )",
                "Штемпельная подушка",
                "Степлер (10)",
                "Ножницы (210)",
                "Ручка шариковая",
                "Скобы для степлера (10)",
                "Скрепка канцелярская (28)",
                "Корректирующая жидкость",
                "Клей-карандаш ",
                "Краска штемпельная",
                "Ручка шариковая (пружина)",
                "Скобы для степлера (24/6)",
                "Клей канцелярский ",
                "Стержень (шариковый)"]

        


# connection string for Test_Recyclables DB
if Test_Mode:
    conn_to_DB = """Driver={SQL Server Native Client 11.0};
                            Server=r78easmondb;
                            Database=OfficeTools;
                            UID=Recyclables;
                            PWD=Qfehz6tQ;"""
else:
    conn_to_DB = """Driver={SQL Server Native Client 11.0};
                            Server=r78easmondb;
                            Database=OfficeTools_Test;
                            UID=Recyclables;
                            PWD=Qfehz6tQ;"""
# connection string for NetworkServicesWebPortal DB
conn_to_NetworkServicesWebPortal = """Driver={SQL Server Native Client 11.0};
                        Server=r78easmondb;
                        Database=NetworkServicesWebPortal;
                        Trusted_Connection=yes;"""

def addlog(type,username,action,status):
    try:
        request_to_DB(f"""exec addlog '{username}', 'OfficeTools', '{action}','{type}', '{status}'""",conn_to_DB)
    except:
        print("Cant send log to DB")

def request_to_DB(request,connection_string):
    # Print the request for debugging purposes
    print(str(request))
    # Try to establish a connection to the database and execute the request
    try:
        with pyodbc.connect(connection_string) as connection:
            cursor = connection.cursor()
            cursor.execute(request)

             # Initialize an empty result list
            result = []
            # Iterate through the rows returned by the query
            # and append them to the result list
            try:
                for row in cursor:
                    # print(row)
                    result.append(row)
            except Exception as e:
                print('Error:',str(e))
                # Close the cursor
            cursor.close()
    # Ensure that the connection and cursor are closed
    # even if an exception occurs
    finally:
        try: cursor.close()
        except: pass
        try: connection.close()
        except: pass
    # Print the number of rows in the result for debugging purposes
    if len(result) < 100:
        print(result)
    return result


# Initialize a Flask app
app = Flask(__name__,static_url_path='/static')
# Set a secret key for the app
# This is used for securely signing cookies and protecting
# against modification of form data
# app.config['SECRET_KEY'] = 'svsm89sdv=-123  1=20me1  j!_@)(#'
app.config['MINIFY_HTML'] = True

# htmlmin = HTMLMIN(app)
# htmlmin = HTMLMIN(app, remove_comments=False, remove_empty_space=True, disable_css_min=True)
# Initialize the Bootstrap extension for the app
bootstrap = Bootstrap(app)


    


# Define a function to get data from the database
def get_data(date_start,date_end,OSP,user,status = ''):
    # Execute a stored procedure in the database
    # and pass in the input parameters
    DB_request = request_to_DB(f"""exec CheckOrders '{status}', '{user}', '{OSP}','{date_start}', '{date_end}'""",conn_to_DB)
    request_to_DB(f"""exec OfficeTools_Test.dbo.AddStatusInWork '1,maxim.chernyakhovich;2,Vitaly.Semenkov;'""",conn_to_DB)
    # Initialize an empty list to store the data
    requests = []
    # Initialize an empty dictionary to store a single request
    request = {}
     # Initialize a list to store the positions in the request
    request['content'] = []
    # If there is data returned by the databas
    # print(DB_request)
    # print(DB_request[0][0])
    if DB_request:
        for row in DB_request:
            # If a new request is encountered, append the current request
            # to the list and reset the request dictionary
            if not('rUID' not in request or request['rUID'] == row[12]):
                requests.append(request)
                request = {}
                request['content'] = []
            # Extract the data from the row and store it in the request dictionary    
            request['date'] = row[0]
            request['status_date'] = row[1]
            request['id'] = row[2]
            request['creator'] = row[3]
            request['ops_num'] = row[4]
            request['status'] = row[5]
            # Initialize a dictionary to store a position in the request
            position = {}
            position['name'] = row[6]
            position['col'] = row[7]
            position['edited_col'] = row[8]
            # Append the position to the list of positions in the request
            request['content'].append(position)
            request['comment'] = row[9]

            request['editor_FIO'] = row[10]
            request['editor_OSP'] = row[11]
            request['rUID'] = row[12]
        # Append the final request to the list of requests
        requests.append(request)
        # Iterate through the requests and calculate the sum of the 'col' and 'edited_col' values
        # for each position in the request
        for request in requests:
            sum_col = 0
            sum_edited_col = 0
            for position in request['content']:
                sum_col+= int(position['col'])
                sum_edited_col+= int(position['edited_col'])
            request['sum_col'] = sum_col
            request['sum_edited_col'] = sum_edited_col

        return requests
    else:
         # If no data is returned by the database, return an empty dictionary
        return {}









# Define a function to get user information from the database
def get_user(sessionId):
    user_DB_info = request_to_DB(f"""SELECT [fullname],[department],[username],[Role],[lastlogin],[SessionID],[id]
                                FROM [NetworkServicesWebPortal].[dbo].[Users]
                                WHERE SessionID = '{sessionId}'""",
                                conn_to_DB)
    # Try to get the role ID and last login time from the user information
    try:
        user_id = user_DB_info[0][6]
        lastlogin = user_DB_info[0][4]
        if Test_Mode:
            lastlogin = datetime.now()
    except:
        # If the user information is not found, return 'session expired'
        return 'session expired'
    # Calculate the time difference between the current time and the last login time
    diff = datetime.now() - lastlogin
    # If the time difference is greater than 1 hour (3600 seconds), return 'session expired'
    if diff.total_seconds() > 3600:
        return 'session expired'
    # Execute a query to get the role description from the database
    try:
        role_id = request_to_DB(f"""SELECT [RoleId]
                                        FROM [NetworkServicesWebPortal].[dbo].[UsersRoles]
                                        WHERE UserId = '{user_id}'""",
                                        conn_to_DB)
        role_DB_info = request_to_DB(f"""SELECT [Description]
                                        FROM [NetworkServicesWebPortal].[dbo].[Roles]
                                        WHERE id = '{role_id[0][0]}'""",
                                        conn_to_DB)[0][0]
    except:
        role_DB_info = 'Пользователь'
    # Initialize a dictionary to store the user information
    user = {}
    # Extract the user information from the database and store it in the dictionary
    user['name'] = user_DB_info[0][0]
    user['department'] = user_DB_info[0][1]
    user['username'] = user_DB_info[0][2]
    user['role'] = role_DB_info

    return user
    
@app.errorhandler(400)
def bad_request(e):
    addlog('Error',last_user,'Error',str(e))
    return render_template('error.html'), 400

@app.errorhandler(401)
def unauthorized(e):
    addlog('Error',last_user,'Error',str(e))
    return render_template('error.html'), 401

@app.errorhandler(403)
def forbidden(e):
    addlog('Error',last_user,'Error',str(e))
    return render_template('error.html'), 403

@app.errorhandler(404)
def not_found(e):
    addlog('Error',last_user,'Error',str(e))
    return render_template('error.html'), 404

@app.errorhandler(409)
def conflict(e):
    addlog('Error',last_user,'Error',str(e))
    return render_template('error.html'), 409

@app.errorhandler(500)
def internal_server_error(e):
    addlog('Error',last_user,'Error',str(e))
    return render_template('error.html'), 500


# Define a route for the app
@app.route("/", methods=['GET'])
def recyclables():
    # Get the session ID from the request
    sessionId = request.args.get('id')
    if Test_Mode:
        sessionId = '453eada4-e722-820f-f6d3-e043a5717516'
    # Get the user information from the databas
    
    user = get_user(sessionId)
    print(user)
    # Print the user information for debugging purposes
    # print(user)
    global last_user 
    # last_user  = user['username']
    week_ago_DB = (datetime.now() - timedelta(weeks=1)).strftime("%Y-%m-%d")
    week_ago = (datetime.now() - timedelta(weeks=1)).strftime("%d-%m-%Y")
    # print(week_ago)
    # addlog(user['username'],'Show main page','Error')
    # If the session has expired or the user information is not found,
    # return 'Ваша сессия истекла' (Your session has expired)
    if user == 'session expired':
        return 'Ваша сессия истекла'
    # If the user has the 'Администратор' role,
    # render the 'recyclables.html' template and pass in the data and filters
    if user['role'] in admin_roles:
        return render_template('office_sklad.html',
                                data = get_data(
                                    user=user['username'],
                                    # user='Maxim.Chernyakhovich',
                                    date_start=week_ago_DB,
                                    # date_start='',
                                    date_end='',
                                    OSP='',
                                    status='Создана'),
                                    status_filter = 'Создана',
                                    search_filter = '',
                                    date_start_filter = week_ago,
                                    date_end_filter = ''
                                         )
    # If the user has the 'Пользователь' role (User),
    # render the 'recyclables_view.html' template and pass in the data and filters
    elif user['role'] in user_roles:
        return render_template('recyclables_view.html',
                                data = get_data(
                                    user=user['username'],
                                    date_start='',
                                    date_end='',
                                    OSP=user['department'],
                                    # OSP='',
                                    status=''),
                                    status_filter = 'Все',
                                    search_filter = user['department'],
                                    # search_filter = '',
                                    date_start_filter = week_ago,
                                    date_end_filter = ''
                                         )
    else:
        return "Доступ закрыт"


# Define a route for the app to handle POST requests
@app.route('/', methods=['POST'])
def recyclables_post():
    # data = request.get_json()
    # checked_ids = data['checkedIds']
    # for checked_id in checked_ids:
        # print("AAAAAAAAAAAAAAAAAAAA"+checked_id)
    try:
        checked_ids = request.form['checkedIds']
        print('checkedIds:',checked_ids)
    # If the search filter is not found, set it to an empty string
    except Exception as e:
        print('Error:',str(e))
        checked_ids = ''
        print('checked_ids:',checked_ids)
    # try:
    #     for form in request.form:
    #         print(form,':::',request.form[form])
    # except:
    #     print(':::')
    # Try to get the search filter from the request form
    try:
        search_filter = request.form['search']
        print('search_filter:',search_filter)
    # If the search filter is not found, set it to an empty string
    except:
        search_filter= ''
        print('search_filter:',search_filter)
    
    # Try to get the date start filter from the request form
    try:
        date_start_filter = request.form['date_start']
        # If the date start filter is not an empty string,
        # reformat it to be compatible with the database
        if date_start_filter != '':
                year, month, day = date_start_filter.split("-")
                date_start_filter_to_DB = f"{day}-{month}-{year}"
        else:
            date_start_filter_to_DB = ""
    # If the date start filter is not found or is invalid,
    # set it to an empty string
    except:
        date_start_filter_to_DB = ""
        date_start_filter = ""
    print('date_start_filter:',date_start_filter)
    print('date_start_filter_to_DB:',date_start_filter_to_DB)

     # Try to get the date end filter from the request form
    try:
        date_end_filter = request.form['date_end']
         # If the date end filter is not an empty string,
        # reformat it to be compatible with the database
        if date_end_filter != '':
                year, month, day = date_end_filter.split("-")
                date_end_filter_to_DB = f"{day}-{month}-{year}"
        else:
            date_end_filter_to_DB = ""
    # If the date end filter is not found or is invalid,
    # set it to an empty string
    except:
        date_end_filter_to_DB = ""
        date_end_filter = ""
    print('date_end_filter:',date_end_filter)
    print('date_end_filter_to_DB:',date_end_filter_to_DB)
    #-----------------------
    try:
        creation_date = request.form['creation_date']
        date_object = datetime.strptime(creation_date, "%d.%m.%Y %H:%M")
        creation_date = date_object.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        print('search_filter:',creation_date)
    except:
        creation_date= ''
        print('creation_date:',creation_date)
    
    #------------------------
    #-----------------------
    try:
        rUID = request.form['rUID']
        print('rUID:',rUID)
    except:
        rUID= ''
        print('rUID:',rUID)
    
    #------------------------
    
    # Try to get the status filter from the request form
    try:
        status_filter = request.form['status']
        # If the status filter is "Все", set it to an empty string
        # to return all statuses from the database
        if status_filter == 'Все':
                status_filter_to_DB = ''
        else:
            status_filter_to_DB = status_filter
        print('ystatus_filter:',status_filter)
        print('ystatus_filter_to_DB:',status_filter_to_DB)
    # If the status filter is not found or is invalid,
    # set it to "Все" and an empty string respectively
    except:
        status_filter= 'Все'
        status_filter_to_DB = ''
        print('nstatus_filter:',status_filter)
        print('nstatus_filter_to_DB:',status_filter_to_DB)

    # Try to get the order number from the submit button in the request form
    try:
        ordernumber = request.form['submit'].split('№')[1]
    # If the order number is not found or is invalid, set it to an empty string
    except: 
        ordernumber = ''
    print('ordernumber:',ordernumber)

    # Try to get the status from the submit button in the request form
    try:
        status = request.form['submit'].split('№')[0]
    # If the status is not found or is invalid, set it to an empty string
    except: 
        status = ''
    print('status:',status)

    if ordernumber != '':
        col_input = []
        edited_col_input = []
        # Iterate through the form and retrieve the form elements that start with "col" and "edited_col"
        # for position in positions:
            
            # col_input.append(request.form["col"+position+"№"+ordernumber])
            # print("col"+position+"№"+ordernumber+":::"+request.form["col"+position+"№"+ordernumber])
            
            # edited_col_input.append(request.form["edited_col"+position+"№"+ordernumber])
            # print("edited_col"+position+"№"+ordernumber+"==="+request.form["edited_col"+position+"№"+ordernumber])
        changes = False
        print('AAAA')
        # Iterate through 'col_input' and compare its elements with the corresponding elements in 'edited_col_input'
        for i in range(0,len(col_input)):
            # print(col_input[i],edited_col_input[i])
            if col_input[i] != edited_col_input[i]:
                # If there is a difference, set 'changes' to True
                changes = True
        print(changes)
        output_positions = ''
        if status == 'confirm' and changes:
            status = '3' #Подтверждена с замечаниями
            for i in range(0,len(edited_col_input)):
                # print(edited_col_input[i])
                if int(edited_col_input[i]) >= 0:
                    output_positions += edited_col_input[i]+","
                else:
                    addlog('Error',last_user,'negative value',str(e))
                    return render_template('error.html')
            output_positions= output_positions[0:-1]
        elif status == 'confirm':
            status = '2'#Подтверждена
            for i in range(0,len(edited_col_input)):
                if int(edited_col_input[i]) >= 0:
                    output_positions += edited_col_input[i]+","
                else:
                    addlog('Error',last_user,'negative value',str(e))
                    return render_template('error.html')
            output_positions= output_positions[0:-1]

        elif status == 'reject':
            status = '4'#Отклонена
            output_positions = ''
        print('status_code:',status)
        print('values:',output_positions)
    # Try to get the comment from the request form
    try:
        comment = request.form['comment']
    # If the comment is not present, set it to an empty string
    except: 
        comment = ''
    print('comment:',comment)
    
     # Get the session ID from the request argument
    sessionId = request.args.get('id')

    if Test_Mode:
        sessionId = 'd9536a0e-4860-8c9c-f952-221b04e46c75'

    # Get the user using the session ID
    user = get_user(sessionId)
    # global last_user
    # last_user  = user['username']
    # If the user is not found or their session has expired
    if user == 'session expired':
        return 'Ваша сессия истекла'
    # addlog(user['username'],'Show page with filters','Error')
    # If the user is an administrator
    if user['role'] in admin_roles:
        # Try to execute the AddChangesAmount stored procedure
        try:
            # #reverse order of output_positions
            # string_list = output_positions.split(',')
            # reversed_string_list = string_list[::-1]
            # flipped_string = ','.join(reversed_string_list)
            # Execute the stored procedure and pass in the necessary parameters

            request_to_DB(f"""EXEC AddChangesAmount '{rUID}', '{output_positions}', '{status}', '{user['username']}', '{comment}' """,conn_to_DB,)
        except Exception as e:
            print('Error:',str(e))
            if str(e) != '''local variable 'output_positions' referenced before assignment''':
                addlog('Error',last_user,'Error',str(e))
                return render_template('error.html')
            

        # render the 'recyclables.html' template and pass in the data and filters
        return render_template('office_sklad.html',
                                data = get_data(
                                    user=user['username'],
                                    date_start=date_start_filter_to_DB,
                                    date_end=date_end_filter_to_DB,
                                    OSP=search_filter,
                                    status=status_filter_to_DB
                                    ),
                                    status_filter = status_filter,
                                    search_filter = search_filter,
                                    date_start_filter = date_start_filter,
                                    date_end_filter = date_end_filter
                                        )
    # render the 'recyclables_view.html' template and pass in the data and filters
    elif user['role'] in user_roles:
        return render_template('recyclables_viev.html',
                                data = get_data(
                                    user=user['username'],
                                    date_start=date_start_filter_to_DB,
                                    date_end=date_end_filter_to_DB,
                                    OSP=user['department'],
                                    # OSP='',
                                    status=status_filter_to_DB
                                    ),
                                    status_filter = status_filter,
                                    search_filter = user['department'],
                                    # search_filter = '',
                                    date_start_filter = date_start_filter,
                                    date_end_filter = date_end_filter)
    else:
        return "Доступ закрыт"



if __name__ == '__main__':
    #start the Flask development server
    try:
        app.run(host="0.0.0.0",debug=True)
    except Exception as e:
        print(f"Error: {e}")
        addlog('Error',last_user,'Error',str(e))
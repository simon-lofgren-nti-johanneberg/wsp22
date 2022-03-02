require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

#Övrig kod 
before do #INTE KLAR MED DENNA
  if (session[:id] ==  nil) && (request.path_info == '')
    # session[:error] = "You need to log in to see this"
    # redirect('/error')
  end
end

#Helpfunctions:
def connection_database(database) 
  db = SQLite3::Database.new(database)
  return db
end

#Routes:
get('/') do
  slim(:home)
end

get('/register') do
  slim(:register)
end

get('/empty_register') do
  slim(:empty_register)
end

get('/wrong_register_password') do
  slim(:wrong_register_password)
end

get ('/username_already_taken') do
  slim(:username_already_taken)
end

get('/login') do
  slim(:login)
end

get('/empty_login') do 
  slim(:empty_login)
end

get('/wrong_login_username') do 
  slim(:wrong_login_username)
end

get('/wrong_login_password') do
  slim(:wrong_login_password)
end

get('/my_exercises_and_workouts') do
  db = connection_database('db/workout.db')
  db.results_as_hash = true
  if session[:choosing_filter] == "all" or session[:choosing_filter] == nil
    #Detta kan göras bättre med inner join (
    @result_workouts = db.execute("SELECT name FROM workouts WHERE user_id = ?", session[:id])
    @result_exercises = db.execute("SELECT name FROM exercises WHERE user_id = ?", session[:id])
    # )
  elsif session[:choosing_filter] == "exercises"
    @result_exercises = db.execute("SELECT name FROM exercises WHERE user_id = ?", session[:id])
  else
    @result_workouts = db.execute("SELECT name FROM workouts WHERE user_id = ?", session[:id])
  end
  #puts "Workouts: #{@result_workouts}"
  #puts "Exercises: #{@result_exercises}"
  slim(:"exercises_and_workouts/index")
end

# get('/albums') do
#   db = SQLite3::Database.new("db/chinook-crud.db")
#   db.results_as_hash = true
#   result = db.execute("SELECT * FROM albums")
#   slim(:"albums/index",locals:{albums:result})
# end

get('/logout') do
  slim(:logout)
end

post('/login') do
  username = params[:username]
  password = params[:password]

  if username == "" or password == ""
    redirect('empty_login')
  else 
    db = connection_database('db/workout.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result == nil
      redirect('wrong_login_username')
    else
      pwdigest = result["pwdigest"]
      id = result["id"]
      if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:username] = username
        redirect('/my_exercises_and_workouts')
      else
        redirect('wrong_login_password')
      end
    end
  end
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  db = connection_database('db/workout.db')
  result = db.execute("SELECT * FROM users WHERE username = ?",username)
  if username == "" or password == "" or password_confirm == ""
    redirect('/empty_register')
  elsif result != []
    redirect('/username_already_taken')
  else
    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/workout.db')
      db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
      redirect('/login')
    else
      redirect('/wrong_register_password')
    end
  end
end

post('/logout') do
  session.destroy
  redirect('/')
end

post('/filter') do
  session[:filter] = params["filter"]
  db = connection_database('db/workout.db')
  db.results_as_hash = true
    case session[:filter]
      when "all"
        session[:choosing_filter] = "all"
      when "exercises"
        session[:choosing_filter] = "exercises"
      when "workouts"
        session[:choosing_filter] = "workouts"
    end
  redirect('/my_exercises_and_workouts')
end


#Till nästa gång: Fixa relationen mellan exercises och muscle groups
#Till senare: Fixa before do's 
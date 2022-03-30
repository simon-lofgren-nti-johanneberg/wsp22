require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

#Helpfunctions:
def connection_database(database) 
  db = SQLite3::Database.new(database)
  return db
end

#Övrig kod 
before do #INTE KLAR MED DENNA
  if (session[:id] ==  nil) && (request.path_info == '')
    # session[:error] = "You need to log in to see this"
    # redirect('/error')
  end
end

#Routes:
get('/') do
  session[:error_message_register] = nil
  session[:error_message_login] = nil
  slim(:home)
end

get('/register') do
  session[:error_message_login] = nil
  slim(:register)
end

get('/login') do
  session[:error_message_register] = nil
  slim(:login)
end

get('/exercises_and_workouts/:id/delete') do  
  session[:type] = params[:type_element]
  slim(:"exercises_and_workouts/delete")
end

get('/exercises_and_workouts/new') do
  db = connection_database('db/workout.db')
  db.results_as_hash = true
  @muscle_groups = db.execute("SELECT type FROM muscle_groups")
  @result_exercises = db.execute("SELECT name FROM exercises WHERE user_id = ?", session[:id])
  # p @muscle_groups
  slim(:"exercises_and_workouts/new")
end

get('/exercises_and_workouts') do
  session[:error_message_new_exercise_or_workout] = nil
  session[:selected_type] = nil
  db = connection_database('db/workout.db')
  db.results_as_hash = true
  if session[:choosing_filter] == "all" or session[:choosing_filter] == nil
    #Detta kan göras bättre med inner join (
    @result_workouts = db.execute("SELECT * FROM workouts WHERE user_id = ?", session[:id])
    @result_exercises = db.execute("SELECT * FROM exercises WHERE user_id = ?", session[:id])
    # )
  elsif session[:choosing_filter] == "exercises"
    @result_exercises = db.execute("SELECT * FROM exercises WHERE user_id = ?", session[:id])
  else
    @result_workouts = db.execute("SELECT * FROM workouts WHERE user_id = ?", session[:id])
  end
  # puts "Workouts: #{@result_workouts}"
  # puts "Exercises: #{@result_exercises}"
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
    session[:error_message_login] = "Your username and/or password can't be empty"
    redirect('/login')
  else 
    db = connection_database('db/workout.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result == nil
      session[:error_message_login] = "Username does not exist"
      redirect('/login')
    else
      pwdigest = result["pwdigest"]
      id = result["id"]
      if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:username] = username
        redirect('/exercises_and_workouts')
      else
        session[:error_message_login] = "Wrong password"
        redirect('/login')
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
    session[:error_message_register] = "One or more of the boxes are empty"
    redirect('/register')
  elsif result != []
    session[:error_message_register] = "Username already taken"
    redirect('/register')
  else
    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/workout.db')
      db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
      redirect('/login')
    else
      session[:error_message_register] = "The passwords don't match"
      redirect('/register')
    end
  end
end

post('/logout') do
  session.destroy
  redirect('/')
end

post('/filter') do
  session[:filter] = params[:filter]
    case session[:filter]
      when "all"
        session[:choosing_filter] = "all"
      when "exercises"
        session[:choosing_filter] = "exercises"
      when "workouts"
        session[:choosing_filter] = "workouts"
    end
  redirect('/exercises_and_workouts')
end

post('/exercises_and_workouts/:id/delete') do
  id = params[:id].to_i
  db = connection_database('db/workout.db')
  if session[:type] == "exercise"
    db.execute("DELETE FROM exercises WHERE id = ?",id)
    db.execute("DELETE FROM relation_exercises_muscle WHERE exercise_id = ?",id)
  else
    db.execute("DELETE FROM workouts WHERE id = ?",id)
  end
  redirect('/exercises_and_workouts')
end 

post('/exercises_and_workouts/new') do
  chosen_muscle_groups = []
  params.each do |element|
    p element
    chosen_muscle_groups << element[0]
  end
  # p "Innan första elementet är borttaget: #{chosen_muscle_groups}"
  chosen_muscle_groups.delete_at 0
  # p "Efter första elementet är borttaget: #{chosen_muscle_groups}"
  # p "Testar att välja första muskelgruppen: #{chosen_muscle_groups[0]}"
  title_exercise = params[:title_exercise]
  title_workout = params[:title_workout]
  if session[:selected_type] == "exercise" && title_exercise != ""
    db = connection_database('db/workout.db')
    db.execute("INSERT INTO exercises (name,user_id) VALUES (?,?)",title_exercise,session[:id])
    exercise_id = db.last_insert_row_id
    chosen_muscle_groups.each do |muscle|
      muscle_group_id = db.execute("SELECT id FROM muscle_groups WHERE type = ?",muscle)
      db.execute("INSERT INTO relation_exercises_muscle (exercise_id,muscle_group_id) VALUES (?,?)",exercise_id,muscle_group_id)
    end
  elsif session[:selected_type] == "workout" && title_workout != ""

  else
    session[:error_message_new_exercise_or_workout] = "Your title can't be empty"
    redirect('/exercises_and_workouts/new')
  end

  #Tillfällig redirect:
  redirect('/exercises_and_workouts/new')
  #
  
  #Inte klar med denna post-route
end

post('/select_type') do 
  type = params[:type]
    case type
      when "select_type"
        session[:error_message_new_exercise_or_workout] = "You must select a type"
      when "exercise"
        session[:error_message_new_exercise_or_workout] = nil
        session[:selected_type] = "exercise"
      when "workout"
        session[:error_message_new_exercise_or_workout] = nil
        session[:selected_type] = "workout"
    end
  redirect('/exercises_and_workouts/new')
end

#Till nästa gång: Relationstabell mellan exercises och muscle_groups
#Till senare: Fixa before do's 

#Istället för en stor del av valideringen, kan kommandot required="required" användas. Det sätts isåfall på samma rad som fälten i forms som måste fyllas i 




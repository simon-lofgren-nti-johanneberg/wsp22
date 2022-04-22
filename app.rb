require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'

enable :sessions

include Module

#Helpfunction:
def destroy_sessions(session1,session2,session3)
  temp1 = session[session1]
  temp2 = session[session2]
  temp3 = session[session3]
  session.destroy
  session[session1] = temp1
  session[session2] = temp2
  session[session3] = temp3
end

#Before do: 
before do 
  if session[:id] ==  nil && request.path_info != '/' && request.path_info != '/register' && request.path_info != '/login' && request.path_info != '/error'
    session[:error] = "Error: Not available route"
    redirect('/error')
  elsif session[:id] !=  nil && (request.path_info == '/' or request.path_info == '/register' or request.path_info == '/login')
    session[:error] = "Error: Not available route"
    redirect('/error') 
  end 
end 

#Routes:
get('/') do
  session.destroy
  slim(:home)
end

get('/error') do 
  destroy_sessions(:id,:filter,:error)
  session[:error]
end

get('/register') do
  destroy_sessions(:error_register,:error_register,:error_register)
  slim(:register)
end

get('/login') do
  destroy_sessions(:error_login,:error_login,:error_login)
  slim(:login)
end

get('/exercises_workouts/:id/delete') do
  destroy_sessions(:id,:filter,:filter)
  id = params[:id]
  db = connection_database('db/workout.db',true)
  # p "db: #{db}"
  # number = function(1)
  # p "number: #{number}"
  type = select_with_two_terms(db,"type","exercises_workouts","id","user_id",id,session[:id]).first

  correct_user(type)

  session[:type_delete] = type["type"]
  slim(:"exercises_workouts/delete")
end

get('/exercises_workouts/:id/edit') do
  destroy_sessions(:id,:filter,:filter)
  id = params[:id]
  db = connection_database('db/workout.db',true)
  type = select_with_two_terms(db,"type","exercises_workouts","id","user_id",id,session[:id]).first

  correct_user(type)

  session[:type_edit] = type["type"]
  @muscle_groups = select_without_term(db,"label","muscle_groups")
  @exercises = select_with_two_terms(db,"title","exercises_workouts","user_id","type",session[:id],"exercise")
  @title = select_with_one_term(db,"title","exercises_workouts","id",id).first
  @included_muscle_groups = select_with_inner_join(db,"label","relation_#{session[:type_edit]}_muscle","muscle_groups","muscle_group_id","id","#{session[:type_edit]}_id",id)

  if session[:type_edit] == "workout" 
    @included_exercises = select_with_inner_join(db,"title","relation_exercise_workout","exercises_workouts","exercise_id","id","workout_id",id)
  end

  slim(:"exercises_workouts/edit")
end

#HÄR

get('/exercises_workouts/new') do
  destroy_sessions(:id,:error_new,:type_new)
  db = connection_database('db/workout.db',true)
  @muscle_groups = select_without_term(db,"label","muscle_groups")
  @exercises = select_with_two_terms(db,"title","exercises_workouts","user_id","type",session[:id],"exercise")
  slim(:"exercises_workouts/new")
end

get('/exercises_workouts/:id') do
  @id = params[:id]
  db = connection_database('db/workout.db',true)
  @data = select_with_one_term(db,"*","exercises_workouts","id",@id).first
  @included_muscle_groups = select_with_inner_join(db,"label","relation_#{@data["type"]}_muscle","muscle_groups","muscle_group_id","id","#{@data["type"]}_id",@id)
  p "Included: #{@included_muscle_groups}"

  if @data["type"] == "workout"
    @included_exercises = select_with_inner_join(db,"title","relation_exercise_workout","exercises_workouts","exercise_id","id","workout_id",@id)
  end

  slim(:"exercises_workouts/show")
end

get('/exercises_workouts/') do
  destroy_sessions(:id,:filter,:error_edit)
  db = connection_database('db/workout.db',true)
  @exercises = select_with_two_terms(db,"*","exercises_workouts","user_id","type",session[:id],"exercise")
  @workouts = select_with_two_terms(db,"*","exercises_workouts","user_id","type",session[:id],"workout")
  if session[:filter] == "exercise"
    @workouts = []
  elsif session[:filter] == "workout"
    @exercises = []
  end
  slim(:"exercises_workouts/index")
end

get('/logout') do
  destroy_sessions(:id,:id,:id)
  slim(:logout)
end

post('/login') do
  username = params[:username]
  password = params[:password]

  empty_fields(username,password,:error_login,'/login')
  db = connection_database('db/workout.db',true)
  user = select_with_one_term(db,"*","users","username",username).first
  existing_user(user)
  password_digest = user["password_digest"]
  id = user["id"]
  correct_password(password_digest,password)
  session[:id] = id
  redirect('/exercises_workouts/')
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  db = connection_database('db/workout.db',true)
  eventual_data = select_with_one_term(db,"*","users","username",username)
  empty_fields(username,password,:error_register,'/register')
  available_user(eventual_data)
  matching_passwords(password,password_confirm)
  password_digest = crypt_password(password)
  insert_to_two_columns(db,"users","username","password_digest",username,password_digest)
  redirect('/login')
end

post('/logout') do
  session.destroy
  redirect('/')
end

post('/filter') do
  destroy_sessions(:id,:id,:filter)
  filter = params[:filter]
    case filter
      when "all"
        session[:filter] = nil
      when "exercise"
        session[:filter] = "exercise"
      when "workout"
        session[:filter] = "workout"
    end
  redirect('/exercises_workouts/')
end

post('/exercises_workouts/:id/delete') do
  id = params[:id]
  db = connection_database('db/workout.db',false)
  delete(db,"exercises_workouts","id",id)
  delete(db,"relation_#{session[:type_delete]}_muscle","#{session[:type_delete]}_id",id)
  delete(db,"relation_exercise_workout","#{session[:type_delete]}_id",id) 
  redirect('/exercises_workouts/')
end 

post('/exercises_workouts/:id/update') do
  title = params[:title].strip
  empty_title(title,:error_edit,'/exercises_workouts/')
  id = params[:id]
  old_title = params[:old_title]
  chosen_muscle_groups = []
  chosen_exercises = []
  db = connection_database('db/workout.db',false)
  eventual_data = select_with_three_terms(db,"*","exercises_workouts","title","user_id","type",title,session[:id],session[:type_edit])
  existing_title_edit(eventual_data,title,old_title)
  session[:error_edit] = nil
  
  params.each do |element|
    if element[0][0, 1] == "m"
      muscle = element[0][1,element[0].length - 1]
      chosen_muscle_groups << muscle
    elsif element[0][0, 1] == "e"
      exercise = element[0][1,element[0].length - 1]
      chosen_exercises << exercise
    end
  end

  update(db,"exercises_workouts","title","user_id","id",title,session[:id],id)
  delete(db,"relation_#{session[:type_edit]}_muscle","#{session[:type_edit]}_id",id)

  chosen_muscle_groups.each do |muscle|
    muscle_group_id = select_with_one_term(db,"id","muscle_groups","label",muscle)
    insert_to_two_columns(db,"relation_#{session[:type_edit]}_muscle","#{session[:type_edit]}_id","muscle_group_id",id,muscle_group_id)
  end

  if session[:type_edit] == "workout"

    delete(db,"relation_exercise_workout","workout_id",id) 

    chosen_exercises.each do |exercise|
      exercise_id = select_with_three_terms(db,"id","exercises_workouts","title","user_id","type",exercise,session[:id],"exercise")
      insert_to_two_columns(db,"relation_exercise_workout","exercise_id","workout_id",exercise_id,id)
    end

  end

  redirect('/exercises_workouts/')
end

post('/select_type') do 
  type = params[:type_new]
    case type
      when "select_type"
        session[:error_new] = "You must select a type"
      when "exercise"
        session[:error_new] = nil
        session[:type_new] = type
      when "workout"
        session[:error_new] = nil
        session[:type_new] = type
    end
  redirect('/exercises_workouts/new')
end

post('/exercises_workouts') do
  title = params[:title].strip
  chosen_muscle_groups = []
  chosen_exercises = []
  db = connection_database('db/workout.db',false)

  empty_title(title,:error_new,'/exercises_workouts/new')
  eventual_data = select_with_three_terms(db,"*","exercises_workouts","title","user_id","type",title,session[:id],session[:type_new])
  existing_title_new(eventual_data)

  # p "Params: #{params}"
  params.each do |element|

    if element[0][0, 1] == "m"
      muscle = element[0][1,element[0].length - 1]
      chosen_muscle_groups << muscle
    elsif element[0][0, 1] == "e"
      exercise = element[0][1,element[0].length - 1]
      chosen_exercises << exercise
    end

  end

  insert_to_three_columns(db,"exercises_workouts","title","user_id","type",title,session[:id],session[:type_new])
  id = db.last_insert_row_id

  chosen_muscle_groups.each do |muscle|
    muscle_group_id = select_with_one_term(db,"id","muscle_groups","label",muscle)
    insert_to_two_columns(db,"relation_#{session[:type_new]}_muscle","#{session[:type_new]}_id","muscle_group_id",id,muscle_group_id)
  end

  if session[:type_new] == "workout"

    chosen_exercises.each do |exercise|
      exercise_id = select_with_three_terms(db,"id","exercises_workouts","title","user_id","type",exercise,session[:id],"exercise")
      insert_to_two_columns(db,"relation_exercise_workout","exercise_id","workout_id",exercise_id,id)
    end

  end
  
  redirect('/exercises_workouts/')
end

#Till nästa gång: Påbörja MVC

#Till senare: Fixa allmän förbättring av kod, Fixa before do's, .....

#Istället för en stor del av valideringen, kan kommandot required="required" användas. Det sätts isåfall på samma rad som fälten i forms som måste fyllas i 




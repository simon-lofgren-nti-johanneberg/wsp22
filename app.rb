require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'

enable :sessions

include Model

# Command which runs before anything else, making sure the user is using a correct route based on login status
#
before do 
  if session[:id] ==  nil && request.path_info != '/' && request.path_info != '/register' && request.path_info != '/login' && request.path_info != '/error'
    session[:error] = "Error: Not available route"
    redirect('/error')
  elsif session[:id] !=  nil && (request.path_info == '/' or request.path_info == '/register' or request.path_info == '/login')
    session[:error] = "Error: Not available route"
    redirect('/error') 
  end 
end 

# Display Landing Page
#
get('/') do
  session.destroy
  slim(:home)
end

# Displays an error message
#
# @see Model#destroy_sessions
#
get('/error') do 
  destroy_sessions(:id,:filter,:error)
  session[:error]
end

# Displays a register form
# 
# @see Model#destroy_sessions
#
get('/register') do
  destroy_sessions(:error_register,:error_register,:error_register)
  slim(:register)
end

# Displays a login form
#
# @see Model#destroy_sessions
#
get('/login') do
  destroy_sessions(:error_login,:error_login,:error_login)
  slim(:login)
end

# Displays a form to confirm delete
#
# @param [Integer] :id, ID of selected exercise or workout to eventually delete
#
# @see Model#destroy_sessions
# @see Model#connection_database
# @see Model#select_with_two_terms
# @see Model#correct_user
#
get('/exercises_workouts/:id/delete') do
  destroy_sessions(:id,:filter,:filter)
  id = params[:id].to_i
  db = connection_database('db/workout.db',true)
  type = select_with_two_terms(db,"type","exercises_workouts","id","user_id",id,session[:id]).first
  correct_user(type)
  session[:type_delete] = type["type"]
  slim(:"exercises_workouts/delete")
end

# Displays an edit form 
#
# @param [Integer] :id, ID of selected exercise or workout to edit
#
# @see Model#destroy_sessions
# @see Model#connection_database
# @see Model#select_with_two_terms
# @see Model#correct_user
# @see Model#select_without_term
# @see Model#select_with_one_term
# @see Model#select_with_inner_join
#
get('/exercises_workouts/:id/edit') do
  destroy_sessions(:id,:filter,:filter)
  id = params[:id].to_i
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

# Displays a create form, based on selected type (exercise or workout) which is made in the connected slim-file (new.slim) if not already done
#
# @see Model#destroy_sessions
# @see Model#connection_database
# @see Model#select_without_term
# @see Model#select_with_two_terms
#
get('/exercises_workouts/new') do
  destroy_sessions(:id,:error_new,:type_new)
  db = connection_database('db/workout.db',true)
  @muscle_groups = select_without_term(db,"label","muscle_groups")
  @exercises = select_with_two_terms(db,"title","exercises_workouts","user_id","type",session[:id],"exercise")
  slim(:"exercises_workouts/new")
end

# Displays details about a specific exercise or workout
#
# @param [Integer] :id, ID of selected exercise or workout to read
#
# @see Model#connection_database
# @see Model#select_with_one_term
# @see Model#select_with_inner_join
#
get('/exercises_workouts/:id') do
  @id = params[:id].to_i
  db = connection_database('db/workout.db',true)
  @data = select_with_one_term(db,"*","exercises_workouts","id",@id).first
  @included_muscle_groups = select_with_inner_join(db,"label","relation_#{@data["type"]}_muscle","muscle_groups","muscle_group_id","id","#{@data["type"]}_id",@id)
  if @data["type"] == "workout"
    @included_exercises = select_with_inner_join(db,"title","relation_exercise_workout","exercises_workouts","exercise_id","id","workout_id",@id)
  end
  slim(:"exercises_workouts/show")
end

# Displays exercises and/or workouts, based on selected filter from connected slim-file (index.slim)
#
# @see Model#destroy_sessions
# @see Model#connection_database
# @see Model#select_with_two_terms
#
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

# Displays a form to confirm logout
#
# @see Model#destroy_sessions
#
get('/logout') do
  destroy_sessions(:id,:id,:id)
  slim(:logout)
end

# Attemps to login, redirect to '/exercises_workouts/' and saving user_id as session
#
# @param [String] :username, User's written username from form
# @param [String] :password, User's written password from form
#
# @see Model#empty_fields
# @see Model#connection_database
# @see Model#select_with_one_term
# @see Model#existing_user
# @see Model#correct_password
#
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

# Attemps to register and redirect to '/login'
#
# @param [String] :username, User's written username from form
# @param [String] :password, User's written password from form
# @param [String] :password_confirm, User's supposed to confirm recent password by writing it again
#
# @see Model#empty_fields
# @see Model#connection_database
# @see Model#select_with_one_term
# @see Model#available_user
# @see Model#matching_passwords
# @see Model#crypt_password
# @see Model#insert_to_two_columns
#
post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  empty_fields(username,password,:error_register,'/register')
  db = connection_database('db/workout.db',true)
  eventual_data = select_with_one_term(db,"*","users","username",username)
  available_user(eventual_data)
  matching_passwords(password,password_confirm)
  password_digest = crypt_password(password)
  insert_to_two_columns(db,"users","username","password_digest",username,password_digest)
  redirect('/login')
end

# Logging out by deleting all sessions, included id of user and redirects to '/'
#
post('/logout') do
  session.destroy
  redirect('/')
end

# Filter types to be seen at the redirect route '/exercises_workouts/'
#
# @param [String] :filter, Selected filter of type from form
#
# @see Model#destroy_sessions
#
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

# Deletes selected exercise or workout and all its data
#
# @param [Integer] :id, ID of selected exercise or workout to delete
#
# @see Model#connection_database
# @see Model#delete
#
post('/exercises_workouts/:id/delete') do
  id = params[:id].to_i
  db = connection_database('db/workout.db',false)
  delete(db,"exercises_workouts","id",id)
  delete(db,"relation_#{session[:type_delete]}_muscle","#{session[:type_delete]}_id",id)
  delete(db,"relation_exercise_workout","#{session[:type_delete]}_id",id) 
  redirect('/exercises_workouts/')
end 

# Attemps to update selected exercise or workout and redirects to '/exercises_workouts/'
#
# @param [Integer] :id, ID of selected exercise or workout to update
# @param [String] :title, Written title of exercise or workout from edit form, removed spaces back and front
# @param [String] :old_title, Recent used title of selected exercise or workout
#
# params.each do |element|: Due to both muscle groups and included exercises are in the same array, they must be seperated in some way when different things are done with them, thereby is an "m" placed before muscle groups and an "e" places before exercises (in the edit form) and that is what is checked here
#
# @see Model#empty_title
# @see Model#connection_database
# @see Model#select_with_three_terms
# @see Model#existing_title_edit
# @see Model#update
# @see Model#delete
# @see Model#select_with_one_term
# @see Model#insert_to_two_columns
# @see Model#select_with_three_terms
#
post('/exercises_workouts/:id/update') do
  id = params[:id].to_i
  title = params[:title].strip
  old_title = params[:old_title]
  chosen_muscle_groups = []
  chosen_exercises = []
  empty_title(title,:error_edit,'/exercises_workouts/')
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

# Attemps to save user's selected type from new.slim in a session, a session used for create, redirects to '/exercises_workouts/new'
#
# @param [String] :type_new, Selected type from new.slim
#
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

# Attemps to create new exercise or workout, based on selected type from new.slim
#
# @param [String] :title, Written title of exercise or workout from new.slim, removed spaces back and front
#
# Explanation for 'params.each do |element|' at post('/exercises_workouts/:id/update')
#
# @see Model#empty_title
# @see Model#connection_database
# @see Model#select_with_three_terms
# @see Model#existing_title_new
# @see Model#insert_to_three_columns
# @see Model#select_with_one_term
# @see Model#insert_to_two_columns
# @see Model#select_with_three_terms
#
post('/exercises_workouts') do
  title = params[:title].strip
  chosen_muscle_groups = []
  chosen_exercises = []
  empty_title(title,:error_new,'/exercises_workouts/new')
  db = connection_database('db/workout.db',false)
  eventual_data = select_with_three_terms(db,"*","exercises_workouts","title","user_id","type",title,session[:id],session[:type_new])
  existing_title_new(eventual_data)
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


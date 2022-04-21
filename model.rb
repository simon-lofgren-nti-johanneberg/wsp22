def connection_database(database,boolean)
    db = SQLite3::Database.new(database)
    db.results_as_hash = boolean
    return db
end

def delete(db,table,term,value) 
    db.execute("DELETE FROM #{table} WHERE #{term} = ?",value)
end

def insert_to_two_columns(db,table,column1,column2,value1,value2)
    db.execute("INSERT INTO #{table} (#{column1},#{column2}) VALUES (?,?)",value1,value2)
end

def insert_to_three_columns(db,table,column1,column2,column3,value1,value2,value3)
    db.execute("INSERT INTO #{table} (#{column1},#{column2},#{column3}) VALUES (?,?,?)",value1,value2,value3)
end

def select_without_term(db,column,table)
    return db.execute("SELECT #{column} FROM #{table}")
end

def select_with_one_term(db,column,table,term,value)
    return db.execute("SELECT #{column} FROM #{table} WHERE #{term} = ?",value)
end

def select_with_two_terms(db,column,table,term1,term2,value1,value2)
    return db.execute("SELECT #{column} FROM #{table} WHERE #{term1} = ? AND #{term2} = ?",value1,value2)
end

def select_with_three_terms(db,column,table,term1,term2,term3,value1,value2,value3)
    db.execute("SELECT #{column} FROM #{table} WHERE #{term1} = ? AND #{term2} = ? AND #{term3} = ?",value1,value2,value3)
end

def select_with_inner_join(db,prime_column,table1,table2,column1,column2,column3,value)
    return db.execute("SELECT #{prime_column} FROM #{table1} INNER JOIN #{table2} ON #{table1}.#{column1} = #{table2}.#{column2} WHERE #{table1}.#{column3} = ?",value)
end

def update(db,table,column1,column2,term,value1,value2,value3)
    db.execute("UPDATE #{table} SET (#{column1},#{column2}) = (?,?) WHERE #{term} = ?",value1,value2,value3)
end

# @included_muscle_groups = db.execute("SELECT label FROM relation_#{session[:type_edit]}_muscle INNER JOIN muscle_groups ON relation_#{session[:type_edit]}_muscle.muscle_group_id = muscle_groups.id WHERE relation_#{session[:type_edit]}_muscle.#{session[:type_edit]}_id = ?",id)

# @included_exercises = db.execute("SELECT title FROM relation_exercise_workout INNER JOIN exercises_workouts ON relation_exercise_workout.exercise_id = exercises_workouts.id WHERE relation_exercise_workout.workout_id = ?",id)

# @included_muscle_groups = db.execute("SELECT label FROM relation_#{@type["type"]}_muscle INNER JOIN muscle_groups ON relation_#{@type["type"]}_muscle.muscle_group_id = muscle_groups.id WHERE relation_#{@type["type"]}_muscle.#{@type["type"]}_id = ?",@id)

# @included_exercises = db.execute("SELECT title FROM relation_exercise_workout INNER JOIN exercises_workouts ON relation_exercise_workout.exercise_id = exercises_workouts.id WHERE relation_exercise_workout.workout_id = ?",@id)







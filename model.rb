module Module

    def available_user(eventual_data)
        if eventual_data != []
            session[:error_register] = "Username already taken"
            redirect('/register')
        end
    end

    def connection_database(database,boolean)
        db = SQLite3::Database.new(database)
        db.results_as_hash = boolean
        return db
    end

    def correct_password(password_digest,password)
        if BCrypt::Password.new(password_digest) != password
            session[:error_login] = "Wrong password"
            redirect('/login')
        end
    end

    def correct_user(type)
        if type == nil 
            session[:error] = "Error: Unauthorized access"
            redirect('/error')
        end
    end

    def crypt_password(password)
        BCrypt::Password.create(password)
    end

    def delete(db,table,term,value) 
        db.execute("DELETE FROM #{table} WHERE #{term} = ?",value)
    end

    def empty_fields(username,password,error,route)
        if username == "" or password == ""
            session[error] = "Your username and/or password can't be empty"
            redirect(route)
        end 
    end

    def empty_title(title,error,route)
        if title == ""
            session[error] = "Error: Title can't be empty"
            redirect(route)
        end
    end

    def existing_title_new(eventual_data)
        if eventual_data != []
            session[:error_new] = "Chosen title of #{session[:type_new]} already exists"
            redirect('/exercises_workouts/new')
        end
    end

    def existing_title_edit(eventual_data,title,old_title)
        if eventual_data != [] && title != old_title
            session[:error_edit] = "Error: Chosen title of #{session[:type_edit]} already exists"
            redirect('/exercises_workouts/')
        end
    end

    def existing_user(user)
        if user == nil
            session[:error_login] = "Username does not exist"
            redirect('/login')
        end
    end

    def insert_to_two_columns(db,table,column1,column2,value1,value2)
        db.execute("INSERT INTO #{table} (#{column1},#{column2}) VALUES (?,?)",value1,value2)
    end

    def insert_to_three_columns(db,table,column1,column2,column3,value1,value2,value3)
        db.execute("INSERT INTO #{table} (#{column1},#{column2},#{column3}) VALUES (?,?,?)",value1,value2,value3)
    end

    def matching_passwords(password,password_confirm)
        if password != password_confirm
            session[:error_register] = "The passwords don't match"
            redirect('/register')
        end
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

end








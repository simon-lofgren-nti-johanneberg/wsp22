module Model # A way to organize the code of the program, variables and functions
    # Checks if written username includes data in database, thereby knowing if username already exist or not
    #
    def available_user(eventual_data)
        if eventual_data != []
            session[:error_register] = "Username already taken"
            redirect('/register')
        end
    end

    # Makes it open to modify to and from database
    #
    # @return db
    #
    def connection_database(database,boolean)
        db = SQLite3::Database.new(database)
        db.results_as_hash = boolean
        return db
    end

    # Checks if written password is matching to username
    #
    def correct_password(password_digest,password)
        if BCrypt::Password.new(password_digest) != password
            session[:error_login] = "Wrong password"
            redirect('/login')
        end
    end

    # The variable type has not got any value if wrong user is in the route, which is why it's value is checked
    #
    def correct_user(type)
        if type == nil 
            session[:error] = "Error: Unauthorized access"
            redirect('/error')
        end
    end

    # Crypts the user's written password with help of BCrypt
    #
    def crypt_password(password)
        BCrypt::Password.create(password)
    end

    # Deleting rows from tables in database based on term
    #
    def delete(db,table,term,value) 
        db.execute("DELETE FROM #{table} WHERE #{term} = ?",value)
    end

    # Removes all unrelevant sessions
    #
    def destroy_sessions(session1,session2,session3)
        temp1 = session[session1]
        temp2 = session[session2]
        temp3 = session[session3]
        session.destroy
        session[session1] = temp1
        session[session2] = temp2
        session[session3] = temp3
    end

    # Makes sure form fields are filled before proceeding further
    #
    def empty_fields(username,password,error,route)
        if username == "" or password == ""
            session[error] = "Your username and/or password can't be empty"
            redirect(route)
        end 
    end

    # Makes sure title in specific form is filled before proceeding further
    #
    def empty_title(title,error,route)
        if title == ""
            session[error] = "Error: Title can't be empty"
            redirect(route)
        end
    end

    # Checks if written title of selected type includes data in database, thereby knowing if title already exist or not 
    #
    def existing_title_new(eventual_data)
        if eventual_data != []
            session[:error_new] = "Chosen title of #{session[:type_new]} already exists"
            redirect('/exercises_workouts/new')
        end
    end

    # Checks if written title of selected type includes data in database, thereby knowing if title already exist or not, as well as checks if title is changed or not which else would be a special case occuring an incorrect error
    #
    def existing_title_edit(eventual_data,title,old_title)
        if eventual_data != [] && title != old_title
            session[:error_edit] = "Error: Chosen title of #{session[:type_edit]} already exists"
            redirect('/exercises_workouts/')
        end
    end

    # Checks if user tries to login with a non existing username
    #
    def existing_user(user)
        if user == nil
            session[:error_login] = "Username does not exist"
            redirect('/login')
        end
    end

    # Inserting data to database, to two different columns in a table
    #
    def insert_to_two_columns(db,table,column1,column2,value1,value2)
        db.execute("INSERT INTO #{table} (#{column1},#{column2}) VALUES (?,?)",value1,value2)
    end

    # Inserting data to database, to three different columns in a table
    #
    def insert_to_three_columns(db,table,column1,column2,column3,value1,value2,value3)
        db.execute("INSERT INTO #{table} (#{column1},#{column2},#{column3}) VALUES (?,?,?)",value1,value2,value3)
    end

    # Checks if both written passwords in register form match with each other
    #
    def matching_passwords(password,password_confirm)
        if password != password_confirm
            session[:error_register] = "The passwords don't match"
            redirect('/register')
        end
    end

    # Selects data from a column in a database table, in this case all title of muscle groups from its table
    #
    # @return [Hash]
    #
    def select_without_term(db,column,table)
        return db.execute("SELECT #{column} FROM #{table}")
    end

    # Selects data from a column in a database table based on term
    #
    # @return [Hash] or double [Array] based on [Boolean] from connection_database() if data was found, else an empty [array]
    #
    def select_with_one_term(db,column,table,term,value)
        return db.execute("SELECT #{column} FROM #{table} WHERE #{term} = ?",value)
    end

    # Selects data from a column in a database table based on two terms
    #
    # @return [Hash] if data was found, else an empty [array]
    #
    def select_with_two_terms(db,column,table,term1,term2,value1,value2)
        return db.execute("SELECT #{column} FROM #{table} WHERE #{term1} = ? AND #{term2} = ?",value1,value2)
    end

    # Selects data from a column in a database table based on three terms
    #
    # @return [Array]
    #
    def select_with_three_terms(db,column,table,term1,term2,term3,value1,value2,value3)
        return db.execute("SELECT #{column} FROM #{table} WHERE #{term1} = ? AND #{term2} = ? AND #{term3} = ?",value1,value2,value3)
    end

    # When data is known from one table but no data is known from the relevant table, the two tables are comparing each other's information to get relevant data from relevant table
    #
    # @return [Hash] if data was found, else an empty [array]
    #
    def select_with_inner_join(db,prime_column,table1,table2,column1,column2,column3,value)
        return db.execute("SELECT #{prime_column} FROM #{table1} INNER JOIN #{table2} ON #{table1}.#{column1} = #{table2}.#{column2} WHERE #{table1}.#{column3} = ?",value)
    end

    # Updates data in specific columns in table based on term
    #
    def update(db,table,column1,column2,term,value1,value2,value3)
        db.execute("UPDATE #{table} SET (#{column1},#{column2}) = (?,?) WHERE #{term} = ?",value1,value2,value3)
    end

end








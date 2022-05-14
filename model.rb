module Model # A way to organize the code of the program, variables and functions
    # Checks if written username includes data in database, thereby knowing if username already exist or not
    #
    # @return [Boolean]
    #
    def available_user(eventual_data)
        eventual_data != []
    end

    # Checks if the current user is not admin by comparing id
    #
    def available_route(user_id)
        user_id != 16
    end

    # Checks if a user is banned 
    #
    def banned(ban)
        ban == 1
    end

    # Checks if written password is matching to username
    #
    def correct_password(password_digest,password)
        BCrypt::Password.new(password_digest) != password
    end

    # The variable type has not got any value if wrong user is in the route, which is why it's value is checked
    #
    def correct_user(type)
        type == nil 
    end

    # Crypts the user's written password with help of BCrypt
    #
    def crypt_password(password)
        BCrypt::Password.create(password)
    end

    # Deleting rows from tables in database based on term
    #
    def delete(table,term,value)
        @db.execute("DELETE FROM #{table} WHERE #{term} = ?",value)
    end

    # Makes sure form fields are filled before proceeding further
    #
    def empty_fields(username,password)
        username == "" or password == ""
    end

    # Makes sure title in specific form is filled before proceeding further
    #
    def empty_title(title)
        title == ""
    end

    # Checks if written title of selected type includes data in database, thereby knowing if title already exist or not, as well as checks if title is changed or not which else would be a special case occuring an incorrect error
    #
    def existing_title(eventual_data,title,old_title)
        eventual_data != [] && title != old_title
    end

    # Checks if user tries to login with a non existing username
    #
    def existing_user(user)
        user == nil
    end

    # Inserting data to database, to two different columns in a table
    #
    def insert_to_two_columns(table,column1,column2,value1,value2)
        @db.execute("INSERT INTO #{table} (#{column1},#{column2}) VALUES (?,?)",value1,value2)
        return nil
    end

    # Inserting data to database, to three different columns in a table
    #
    # @return [Integer]
    #
    def insert_to_three_columns(table,column1,column2,column3,value1,value2,value3)
        @db.execute("INSERT INTO #{table} (#{column1},#{column2},#{column3}) VALUES (?,?,?)",value1,value2,value3)
        return @db.last_insert_row_id
    end

    # Checks if both written passwords in register form match with each other
    #
    def matching_passwords(password,password_confirm)
        password != password_confirm
    end

    # Selects data from a column in a database table, in this case all title of muscle groups from its table
    #
    # @return [Hash]
    #
    def select_without_term(column,table)
        return @db.execute("SELECT #{column} FROM #{table}")
    end

    # Selects data from a column in a database table based on term
    #
    # @return [Hash] or double [Array] based on [Boolean] from connection_database() if data was found, else an empty [array]
    #
    def select_with_one_term(column,table,term,value)
        return @db.execute("SELECT #{column} FROM #{table} WHERE #{term} = ?",value)
    end

    # Selects data from a column in a database table based on two terms
    #
    # @return [Hash] if data was found, else an empty [array]
    #
    def select_with_two_terms(column,table,term1,term2,value1,value2)
        return @db.execute("SELECT #{column} FROM #{table} WHERE #{term1} = ? AND #{term2} = ?",value1,value2)
    end

    # Selects data from a column in a database table based on three terms
    #
    # @return [Array]
    #
    def select_with_three_terms(column,table,term1,term2,term3,value1,value2,value3)
        return @db.execute("SELECT #{column} FROM #{table} WHERE #{term1} = ? AND #{term2} = ? AND #{term3} = ?",value1,value2,value3)
    end

    # When data is known from one table but no data is known from the relevant table, the two tables are comparing each other's information to get relevant data from relevant table
    #
    # @return [Hash] if data was found, else an empty [array]
    #
    def select_with_inner_join(prime_column,table1,table2,column1,column2,column3,value)
        return @db.execute("SELECT #{prime_column} FROM #{table1} INNER JOIN #{table2} ON #{table1}.#{column1} = #{table2}.#{column2} WHERE #{table1}.#{column3} = ?",value)
    end

    # Connects to database which makes it open to modify to and from
    #
    def set_db()
        @db = SQLite3::Database.new('db/workout.db')
        @db.results_as_hash = true
    end

    # Updates data in one specific column in table based on term
    #
    def update_to_one_column(table,column1,term,value1,value2)
        @db.execute("UPDATE #{table} SET #{column1} = ? WHERE #{term} = ?",value1,value2)
    end

    # Updates data in two specific columns in table based on term
    #
    def update_to_two_columns(table,column1,column2,term,value1,value2,value3)
        @db.execute("UPDATE #{table} SET (#{column1},#{column2}) = (?,?) WHERE #{term} = ?",value1,value2,value3)
    end

end






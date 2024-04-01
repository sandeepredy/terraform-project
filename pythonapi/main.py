from flask import Flask, jsonify, request 
  
# creating a Flask app 
app = Flask(__name__) 
  
# on the terminal type: curl http://127.0.0.1:5000/get-user/123?extra="hello" 
# returns userdata or info when we use GET.
@app.route("/get-user/<user_id>", methods = ['GET']) 
def get_user(user_id): 
    user_data ={
        "user_id":user_id,
        "name":"python docker test app",
        "email":"random@gmail.com"
    }

    # extra = request.args.get("extra")
    # if extra:
    #     user_data["extra"] = extra
    return jsonify(user_data), 200 

# on the terminal type: curl http://127.0.0.1:5000/create-user" 
# creates and returns userdata usingPost.
@app.route("/create-user", methods = ['POST']) 
def create_user(): 
    data = request.get_json()
    return jsonify(data), 201 


# on the terminal type: curl http://127.0.0.1:5000/ 
# returns hello world when we use GET. 
# returns the data that we send when we use POST. 
@app.route('/', methods = ['GET', 'POST']) 
def home(): 
    if(request.method == 'GET'):   
        resp = "hello world"
        print("helloworld")
        return jsonify({'resp': resp}) 
  
  
# A simple function to calculate the square of a number 
# the number to be squared is sent in the URL when we use GET 
# on the terminal type: curl http://127.0.0.1:5000/home/10 
# this returns 100 (square of 10) 
@app.route('/home/<int:num>', methods = ['GET']) 
def disp(num): 
  
    return jsonify({'sq of num': num**2}) 
  
  
# driver function 
if __name__ == '__main__': 
  
    #app.run(debug = True) 
    app.run(host='0.0.0.0' , port=3000)
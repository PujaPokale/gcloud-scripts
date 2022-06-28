import flask


# HTTP cloud function
def greet_name(request):

    request_arguments = request.args
    
    if request_arguments and "name" in request_arguments:
        name = request_arguments["name"]

    else:
        name = "There"

    return "Hi {}..".format(flask.escape(name))    


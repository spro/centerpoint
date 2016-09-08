polar = require 'somata-socketio'
app = polar port: 3365
app.get '/', (req, res) -> res.render 'app' 
app.start()

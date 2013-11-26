express = require 'express'
http = require 'http'
path = require 'path'
redis = require 'then-redis'
_ = require 'lodash'
#database = require './database'

# ---------------------------------------------------------------

app = express()

Router = require 'reversable-router'

router = new Router()
router.extendExpress(app)
router.registerAppHelpers(app)

reverseSitesMap = {}

port = process.env.PORT || 3000

appConf =
    router: router




# ---------------------------------------------------------------

app.use express.compress()
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.cookieSession
    secret: 'whfweduy2d23d'

#authentication = require('./authentication')
#authentication.configureApp(app, appConf)
#require('./controllers/uploadSessions').configureApp(app, appConf)

# Static files
app.use(express.static('static'))
app.use(express.static('bower_components'))

# Error handler
if 'development' == app.get('env')
    app.use(express.errorHandler())

# ---------------------------------------------------------------

#cmdLineArgs = process.argv.slice(2)
#
#if cmdLineArgs.length > 0
#    if cmdLineArgs[0] == 'setCredentials'
#        site = cmdLineArgs[1]
#        username = cmdLineArgs[2]
#        password = cmdLineArgs[3]
#        authentication.setCredentials(site, username, password, {}, true, appConf)
#        .then (msg) ->
#                console.log(msg)
#                process.exit 0
#        .otherwise (reason) ->
#                console.log(reason)
#                process.exit 1
#    else
#        console.log "Unknown command #{cmdLineArgs[0]}"
#        process.exit 1
#else
http.createServer(app).listen port, () ->
    console.log('Server listening on http://localhost:' + port)

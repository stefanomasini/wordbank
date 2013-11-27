exports.configureApp = (app, appConf) ->
    app.post '/changes', 'changes', (req, res) ->
        changes = JSON.parse(req.param('data')).changes
        appConf.db.saveChanges(changes)
            .then () ->
                res.json
                    status: 'ok'

    app.get '/words', 'words', (req, res) ->
        appConf.db.getWords()
            .then (words) ->
                    res.json
                        words: words

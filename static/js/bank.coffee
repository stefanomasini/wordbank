define ['lodash'], (_) ->
    class Bank
        constructor: (listener) ->
            @words = {}
            @listener = listener

        initialize: (words) ->
            for word in words
                @words[word.src] = word

        getSize: () -> _.size(@words)

        addNewWord: (word) ->
            @words[word] =
                src: word
                epochUTCms: new Date().getTime()
                memorizationAttempts: []
            @listener?(@words[word])

        getAllNewWords: () ->
            (new Word(word, @listener) for word in _.values(@words) when not word.translation)

        getAllTranslatedWords: () ->
            (new Word(word, @listener) for word in _.values(@words) when word.translation)

        setTranslation: (word, translation) ->
            if not @words[word]
                @addNewWord(word)
            @words[word].translation = translation
            @words[word].epochUTCms = new Date().getTime()
            @listener?(@words[word])

        getTranslationFor: (word) -> @words[word]?.translation

        getWord: (word) ->
            if @words[word]
                new Word(@words[word], @listener)

        removeWord: (word) ->
            delete @words[word]
            @listener?({src: word, delete: true})

        renameWord: (oldWord, newWord) ->
            w = @words[oldWord]
            w.src = newWord
            @words[newWord] = w
            @listener?(@words[newWord])
            @removeWord(oldWord)


    class Word
        constructor: (word, listener) ->
            @word = word
            @listener = listener

        getWord: () -> @word.src

        getTranslation: () -> @word.translation

        setTranslation: (translation) ->
            @word.translation = translation
            @word.epochUTCms = new Date().getTime()
            @listener?(@word)

        getMemorizationAttempts: (fromSource) -> (attempt for attempt in @word.memorizationAttempts when attempt.fromSource == fromSource)

        attemptMemorization: (success, fromSource) ->
            @word.memorizationAttempts.push
                success: success
                fromSource: fromSource
                epochUTCms: new Date().getTime()
            @listener?(@word)

        getNumSuccessfulMemorizationAttempts: (fromSource) ->
            counter = 0
            if @word.memorizationAttempts.length > 0
                for idx in [@word.memorizationAttempts.length-1 .. 0]
                    if @word.memorizationAttempts[idx].fromSource == fromSource
                        if @word.memorizationAttempts[idx].success == true
                            counter += 1
                        else
                            break
            return counter

        isKnown: (fromSource) -> @getNumSuccessfulMemorizationAttempts(fromSource) > 0

        isKnownBothWays: () -> @isKnown(true) && @isKnown(false)


    class Learning
        constructor: (bank) ->
            @bank = bank
            @lastChosenWords = []

        fetchNext: () ->
            randomNumber = Math.random()
            allWords = @bank.getAllTranslatedWords()
            if allWords.length == 0
                return [null, null]
            words = (word for word in allWords when word.getWord() not in @lastChosenWords)
            chosenWord = null
            fromSource = null
            for wp in @getWordProbabilities(words)
                chosenWord = wp.word
                fromSource = wp.fromSource
                randomNumber -= wp.prob
                if randomNumber < 0
                    break
            @lastChosenWords.push chosenWord.getWord()
            while @lastChosenWords.length > Math.min(3, allWords.length-1)
                @lastChosenWords.splice(0, 1)
            return [chosenWord, fromSource]

        getWordProbabilities: (words) ->
            knownWords = []
            totalForKnownWords = 0
            unknownWords = []
            totalForUnknownWords = 0
            for word in words
                for fromSource in [true, false]
                    numSuccessfulAttempts = word.getNumSuccessfulMemorizationAttempts(fromSource)
                    if numSuccessfulAttempts > 0
                        weight = 4 - Math.min(3, numSuccessfulAttempts)
                        totalForKnownWords += weight
                        knownWords.push [word, fromSource, weight]
                    else
                        weight = 1 / (word.getMemorizationAttempts(fromSource).length+1)
                        totalForUnknownWords += weight
                        unknownWords.push [word, fromSource, weight]
            probabilities = []
            if knownWords.length > 0 and unknownWords.length > 0
                knownSectionTotal = 0.25
                unknownSectionTotal = 0.75
            else
                knownSectionTotal = unknownSectionTotal = 1
            for [word, fromSource, weight] in knownWords
                probabilities.push {word:word, fromSource:fromSource, weight:weight * knownSectionTotal, prob:weight * knownSectionTotal / totalForKnownWords}
            for [word, fromSource, weight] in unknownWords
                probabilities.push {word:word, fromSource:fromSource, weight:weight * unknownSectionTotal, prob:weight * unknownSectionTotal / totalForUnknownWords}
            return probabilities


    class Saver
        constructor: () ->
            @spool = {}

        notify: (change) ->
            if !@spool[change.src] || change.epochUTCms > @spool[change.src].epochUTCms || change.delete
                @spool[change.src] = change

        startSaving: () ->
            changes = (v for v in _.values(@spool) when !v.delete)
            deletes = (v.src for v in _.values(@spool) when v.delete)
            @spool = {}
            return {
                changes: changes
                deletes: deletes
                revert: () =>
                    for change in changes
                        @notify(change)
            }


    return {
        Bank: Bank
        Learning: Learning
        Saver: Saver
    }


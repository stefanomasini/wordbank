define ['lodash'], (_) ->
    class Bank
        constructor: () ->
            @words = {}

        getSize: () -> _.size(@words)

        addNewWord: (word) ->
            @words[word] =
                src: word
                memorizationAttempts: []

        getAllNewWords: () ->
            (new Word(word) for word in _.values(@words) when not word.translation)

        getAllTranslatedWords: () ->
            (new Word(word) for word in _.values(@words) when word.translation)

        setTranslation: (word, translation) ->
            if not @words[word]
                @addNewWord(word)
            @words[word].translation = translation

        getTranslationFor: (word) -> @words[word]?.translation

        getWord: (word) ->
            if @words[word]
                new Word(@words[word])


    class Word
        constructor: (word) ->
            @word = word

        getWord: () -> @word.src

        getTranslation: () -> @word.translation

        setTranslation: (translation) ->
            @word.translation = translation
            @word.epochUTCms = new Date().getTime()

        getMemorizationAttempts: (fromSource) -> (attempt for attempt in @word.memorizationAttempts when attempt.fromSource == fromSource)

        attemptMemorization: (success, fromSource) ->
            @word.memorizationAttempts.push
                success: success
                fromSource: fromSource
                epochUTCms: new Date().getTime()

        getNumSuccessfulMemorizationAttempts: (fromSource) ->
            counter = 0
            if @word.memorizationAttempts.length > 0
                for idx in [@word.memorizationAttempts.length-1 .. 0]
                    if @word.memorizationAttempts[idx].success == true && @word.memorizationAttempts[idx].fromSource == fromSource
                        counter += 1
                    else
                        break
            return counter

        isKnown: (fromSource) -> @getNumSuccessfulMemorizationAttempts(fromSource) > 0


    class Learning
        constructor: (bank) ->
            @bank = bank
            @lastChosenWords = []

        fetchNext: () ->
            randomNumber = Math.random()
            allWords = @bank.getAllTranslatedWords()
            words = (word for word in allWords when word.getWord() not in @lastChosenWords)
            chosenWord = null
            for [chosenWord, fromSource, probability] in @getWordProbabilities(words)
                randomNumber -= probability
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
            sectionTotal = if knownWords.length > 0 and unknownWords.length > 0 then 0.5 else 1
            for [word, fromSource, weight] in knownWords
                probabilities.push [word, fromSource, weight * sectionTotal / totalForKnownWords]
            for [word, fromSource, weight] in unknownWords
                probabilities.push [word, fromSource, weight * sectionTotal / totalForUnknownWords]
            return probabilities


    return {
        Bank: Bank
        Learning: Learning
    }


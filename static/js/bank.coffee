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

        getTranslationFor: (word) ->
            @words[word]?.translation

        getWord: (word) ->
            if @words[word]
                new Word(@words[word])


    class Word
        constructor: (word) ->
            @word = word

        getWord: () ->
            return @word.src

        getTranslation: () ->
            return @word.translation

        setTranslation: (translation) ->
            @word.translation = translation
            @word.epochUTCms = new Date().getTime()

        getMemorizationAttempts: () ->
            return @word.memorizationAttempts

        attemptMemorization: (success) ->
            @word.memorizationAttempts.push
                success: success
                epochUTCms: new Date().getTime()

        getNumSuccessfulMemorizationAttempts: () ->
            counter = 0
            if @word.memorizationAttempts.length > 0
                for idx in [@word.memorizationAttempts.length-1 .. 0]
                    if @word.memorizationAttempts[idx].success == true
                        counter += 1
                    else
                        break
            return counter

        isKnown: () ->
            return @getNumSuccessfulMemorizationAttempts() > 0


    class Learning
        constructor: (bank) ->
            @bank = bank
            @lastChosenWords = []

        fetchNext: () ->
            randomNumber = Math.random()
            allWords = @bank.getAllTranslatedWords()
            words = (word for word in allWords when word.getWord() not in @lastChosenWords)
            chosenWord = null
            for [word, probability] in _.pairs(@getWordProbabilities(words))
                randomNumber -= probability
                if randomNumber < 0
                    break
            chosenWord = @bank.getWord(word)
            @lastChosenWords.push chosenWord.getWord()
            while @lastChosenWords.length > Math.min(3, allWords.length-1)
                @lastChosenWords.splice(0, 1)
            return chosenWord

        getWordProbabilities: (words) ->
            knownWords = []
            totalForKnownWords = 0
            unknownWords = []
            totalForUnknownWords = 0
            for word in words
                numSuccessfulAttempts = word.getNumSuccessfulMemorizationAttempts()
                if numSuccessfulAttempts > 0
                    weight = 4 - Math.min(3, numSuccessfulAttempts)
                    totalForKnownWords += weight
                    knownWords.push [word, weight]
                else
                    weight = 1 / (word.getMemorizationAttempts().length+1)
                    totalForUnknownWords += weight
                    unknownWords.push [word, weight]
            probabilities = {}
            sectionTotal = if knownWords.length > 0 and unknownWords.length > 0 then 0.5 else 1
            for [word, weight] in knownWords
                probabilities[word.getWord()] = weight * sectionTotal / totalForKnownWords
            for [word, weight] in unknownWords
                probabilities[word.getWord()] = weight * sectionTotal / totalForUnknownWords
            return probabilities


    return {
        Bank: Bank
        Learning: Learning
    }


define ['js/bank'], (bankMod) ->


    describe 'bank', () ->
        bank = null
        changes = []

        beforeEach () ->
            changes = []
            bank = new bankMod.Bank (c) -> changes.push(c)

        it 'can add new word', () ->
            expect(bank.getSize()).toEqual(0)
            bank.addNewWord('foo')
            expect(bank.getSize()).toEqual(1)
            expect(changes.length).toEqual(1)
            expect(changes[0].src).toEqual('foo')

        it 'can list all new words', () ->
            bank.addNewWord('foo')
            bank.addNewWord('bar')
            bank.addNewWord('bar')
            expect(bank.getAllNewWords().length).toEqual(2)
            expect(changes.length).toEqual(3)

        it 'can accept a word translation and remembers it', () ->
            bank.addNewWord('foo')
            bank.setTranslation('foo', 'fooTranslated')
            bank.setTranslation('bar', 'barTranslated')
            expect(bank.getTranslationFor('foo')).toEqual('fooTranslated')
            expect(bank.getTranslationFor('bar')).toEqual('barTranslated')
            expect(bank.getTranslationFor('other')).toBeUndefined()
            expect(changes.length).toEqual(4)

        it 'can list all translated words', () ->
            bank.addNewWord('foo')
            bank.setTranslation('bar', 'barTranslated')
            bank.setTranslation('baz', 'bazTranslated')
            expect(bank.getAllTranslatedWords().length).toEqual(2)

        it 'returns clever word objects', () ->
            expect(bank.getWord('foo')).toBeUndefined()
            bank.setTranslation('foo', 'fooTranslated')
            expect(bank.getWord('foo')).toBeDefined()
            expect(bank.getWord('foo').getWord()).toEqual('foo')
            expect(bank.getWord('foo').getTranslation()).toEqual('fooTranslated')


    describe 'word', () ->
        bank = null
        word = null
        changes = []

        beforeEach () ->
            bank = new bankMod.Bank (c) -> changes.push(c)
            bank.setTranslation('foo', 'fooTranslated')
            word = bank.getWord('foo')
            changes = []

        it 'feeds back into bank', () ->
            word.setTranslation('anotherTranslaction')
            expect(bank.getTranslationFor('foo')).toEqual('anotherTranslaction')
            expect(changes.length).toEqual(1)

        it 'stores memorization attempts', () ->
            expect(word.getMemorizationAttempts(true).length).toEqual(0)
            word.attemptMemorization(true, true)
            expect(word.getMemorizationAttempts(true).length).toEqual(1)
            expect(word.getMemorizationAttempts(true)[0].success).toEqual(true)
            expect(changes.length).toEqual(1)

        it 'evaluates the memorization level', () ->
            expect(word.getNumSuccessfulMemorizationAttempts(true)).toEqual(0)
            word.attemptMemorization(true, true)
            expect(word.getNumSuccessfulMemorizationAttempts(true)).toEqual(1)
            word.attemptMemorization(true, true)
            expect(word.getNumSuccessfulMemorizationAttempts(true)).toEqual(2)
            word.attemptMemorization(false, true)
            expect(word.getNumSuccessfulMemorizationAttempts(true)).toEqual(0)
            word.attemptMemorization(true, true)
            expect(word.getNumSuccessfulMemorizationAttempts(true)).toEqual(1)

        it 'can tell whether a word is known', () ->
            expect(word.isKnown(true)).toBeFalsy()
            word.attemptMemorization(true, true)
            expect(word.isKnown(true)).toBeTruthy()
            word.attemptMemorization(false, true)
            expect(word.isKnown(true)).toBeFalsy()
            word.attemptMemorization(true, true)
            expect(word.isKnown(true)).toBeTruthy()


    describe 'learning algorithm', () ->
        bank = null
        allWords = null
        learning = null

        beforeEach () ->
            bank = new bankMod.Bank()
            allWords = []
            for i in [1..10]
                bank.setTranslation("#{i}", "#{i}t")
                allWords.push(bank.getWord("#{i}"))
            learning = new bankMod.Learning(bank)

        makeKey = ([word, fromSource]) -> "#{word.getWord()}-#{if fromSource then 'fromSource' else 'fromTranslation'}"
        calculateProbabilitiesMap = () ->
            probabilities = learning.getWordProbabilities(bank.getAllTranslatedWords())
            return _.zipObject([makeKey([word, fromSource]), probability] for [word, fromSource, probability] in probabilities)

        it 'fetches a different word at every attempt', () ->
            lastWord = makeKey(learning.fetchNext())
            for i in [1..20]
                nextWord = makeKey(learning.fetchNext())
                expect(nextWord).not.toEqual(lastWord)
                lastWord = nextWord

        it 'computes probability for each word to be chosen as next', () ->
            allProbabilities = (probability for [chosenWord, fromSource, probability] in learning.getWordProbabilities(bank.getAllTranslatedWords()))
            totalProbability = _.reduce allProbabilities, (a,b) -> a+b
            expect(Math.abs(totalProbability - 1)).toBeLessThan(0.00001)

        it 'splits probability equally between known and unknown words', () ->
            for word in allWords[..3]
                word.attemptMemorization(true, true)
            totalProbabilityForKnown = 0
            totalProbabilityForUnknown = 0
            for [word, fromSource, probability] in learning.getWordProbabilities(bank.getAllTranslatedWords())
                if word.isKnown(fromSource)
                    totalProbabilityForKnown += probability
                else
                    totalProbabilityForUnknown += probability
            expect(Math.abs(totalProbabilityForKnown - 0.5)).toBeLessThan(0.00001)
            expect(Math.abs(totalProbabilityForUnknown - 0.5)).toBeLessThan(0.00001)

        it 'makes lesser known words more likely to be chosen', () ->
            bank.getWord('1').attemptMemorization(true, true)
            bank.getWord('2').attemptMemorization(true, true)
            bank.getWord('2').attemptMemorization(true, true)
            bank.getWord('3').attemptMemorization(true, true)
            bank.getWord('3').attemptMemorization(true, true)
            bank.getWord('3').attemptMemorization(true, true)
            probabilities = calculateProbabilitiesMap()
            expect(probabilities['1-fromSource']).toBeGreaterThan(probabilities['2-fromSource'] + 0.001)
            expect(probabilities['2-fromSource']).toBeGreaterThan(probabilities['3-fromSource'] + 0.001)

        it 'favours words that have the least number of attempts', () ->
            bank.getWord('1').attemptMemorization(false, true)
            probabilities = calculateProbabilitiesMap()
            expect(probabilities['1-fromSource']).toBeLessThan(probabilities['2-fromSource'] - 0.001)
            expect(Math.abs(probabilities['2-fromSource'] - probabilities['3-fromSource'])).toBeLessThan(0.001)

        it 'considers memorization attempts from both source and translation', () ->
            probabilities = calculateProbabilitiesMap()
            expect(_.size(probabilities)).toEqual(bank.getAllTranslatedWords().length * 2)
            expect(Math.abs(probabilities['1-fromSource'] - probabilities['1-fromTranslation'])).toBeLessThan(0.001)

            bank.getWord('1').attemptMemorization(true, false)
            probabilities = calculateProbabilitiesMap()
            expect(Math.abs(probabilities['1-fromSource'])).toBeLessThan(probabilities['1-fromTranslation'] - 0.001)

    describe 'saver', () ->
        change = (src, ts) ->
            src: src
            epochUTCms: ts

        saver = null

        beforeEach () ->
            saver = new bankMod.Saver()

        it 'collects changes by increasing timestamp', () ->
            saver.notify change('foo', 2)
            expect(_.size(saver.spool)).toEqual(1)
            saver.notify change('foo', 3)
            expect(_.size(saver.spool)).toEqual(1)
            saver.notify change('foo', 1)
            expect(saver.spool['foo'].epochUTCms).toEqual(3)

        it 'spawns a different spool when saving is in progress that can be merged back in case of error', () ->
            saver.notify change('foo', 1)
            saver.notify change('bar', 2)
            saving = saver.startSaving()
            expect(_.size(saver.spool)).toEqual(0)
            expect(saving.changes.length).toEqual(2)

            saver.notify change('bar', 3)
            expect(_.size(saver.spool)).toEqual(1)

            saving.revert()
            expect(_.size(saver.spool)).toEqual(2)
            expect(saver.spool['bar'].epochUTCms).toEqual(3)
            expect(saver.spool['foo'].epochUTCms).toEqual(1)

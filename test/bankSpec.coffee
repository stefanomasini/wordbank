define ['js/bank'], (bankMod) ->


    describe 'bank', () ->
        bank = null

        beforeEach () ->
            bank = new bankMod.Bank()

        it 'can add new word', () ->
            expect(bank.getSize()).toEqual(0)
            bank.addNewWord('foo')
            expect(bank.getSize()).toEqual(1)

        it 'can list all new words', () ->
            bank.addNewWord('foo')
            bank.addNewWord('bar')
            bank.addNewWord('bar')
            expect(bank.getAllNewWords().length).toEqual(2)

        it 'can accept a word translation and remembers it', () ->
            bank.addNewWord('foo')
            bank.setTranslation('foo', 'fooTranslated')
            bank.setTranslation('bar', 'barTranslated')
            expect(bank.getTranslationFor('foo')).toEqual('fooTranslated')
            expect(bank.getTranslationFor('bar')).toEqual('barTranslated')
            expect(bank.getTranslationFor('other')).toBeUndefined()

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

        beforeEach () ->
            bank = new bankMod.Bank()
            bank.setTranslation('foo', 'fooTranslated')
            word = bank.getWord('foo')

        it 'feeds back into bank', () ->
            word.setTranslation('anotherTranslaction')
            expect(bank.getTranslationFor('foo')).toEqual('anotherTranslaction')

        it 'stores memorization attempts', () ->
            expect(word.getMemorizationAttempts(true).length).toEqual(0)
            word.attemptMemorization(true, true)
            expect(word.getMemorizationAttempts(true).length).toEqual(1)
            expect(word.getMemorizationAttempts(true)[0].success).toEqual(true)

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

// Complete Wordle Game Backend Logic
class WordleGameBackend {
    constructor() {
        this.wordLength = 5;
        this.maxGuesses = 6;
        this.currentGuess = '';
        this.currentRow = 0;
        this.gameOver = false;
        this.gameWon = false;
        this.guesses = [];
        this.feedback = [];
        
        // Game state
        this.secretWord = 'RIVER';
        this.gameStarted = false;
        
        // Word list for validation
        this.wordList = [
            'APPLE', 'BRAIN', 'CHAIR', 'DANCE', 'EARTH', 'FOCUS', 'GRANT', 'HAPPY',
            'IDEAL', 'JOKER', 'KNIFE', 'LEMON', 'MAGIC', 'NIGHT', 'OCEAN', 'POWER',
            'QUICK', 'RIVER', 'SMART', 'TIGER', 'UNITY', 'VALUE', 'WORLD', 'YOUTH',
            'ZEBRA', 'ABOUT', 'BEACH', 'CLEAN', 'DREAM', 'EAGER', 'FAITH', 'GRACE',
            'HEART', 'IMAGE', 'JOINT', 'KNOCK', 'LEARN', 'MUSIC', 'NOVEL', 'ORDER',
            'PEACE', 'QUEST', 'RIGHT', 'SMILE', 'TRUTH', 'UNION', 'VOICE', 'WOMAN',
            'CRANE', 'SLATE', 'ADIEU', 'AUDIO', 'RAISE', 'AROSE', 'STARE', 'TEARS',
            'REACT', 'TRACE', 'CRATE', 'CARET', 'CATER', 'ALTER', 'LATER', 'ALERT',
            'THISS', 'THING', 'THINK', 'THIRD', 'THOSE', 'THREE', 'THREW', 'THROW',
            'BLADE', 'BLAME', 'BLANK', 'BLIND', 'BLOCK', 'BLOOD', 'BOARD', 'BOOST',
            'BOUND', 'BRAVE', 'BREAK', 'BREED', 'BRICK', 'BRIDE', 'BRING', 'BROAD',
            'BROKE', 'BROWN', 'BUILD', 'BUILT', 'CABLE', 'CARRY', 'CATCH', 'CAUSE',
            'CHECK', 'CHEST', 'CHIEF', 'CHILD', 'CHINA', 'CHOSE', 'CIVIL', 'CLAIM',
            'CLASS', 'CLEAN', 'CLEAR', 'CLICK', 'CLIMB', 'CLOCK', 'CLOSE', 'CLOUD',
            'COACH', 'COAST', 'COULD', 'COUNT', 'COURT', 'COVER', 'CRAFT', 'CRASH',
            'CRAZY', 'CREAM', 'CRIME', 'CROSS', 'CROWD', 'CROWN', 'CRUDE', 'CURVE',
            'CYCLE', 'DAILY', 'DANCE', 'DATED', 'DEALT', 'DEATH', 'DEBUT', 'DELAY',
            'DEPTH', 'DOING', 'DOUBT', 'DOZEN', 'DRAFT', 'DRAMA', 'DRANK', 'DRAWN',
            'DREAM', 'DRESS', 'DRILL', 'DRINK', 'DRIVE', 'DROVE', 'DYING', 'EAGER',
            'EARLY', 'EARTH', 'EIGHT', 'ELITE', 'EMPTY', 'ENEMY', 'ENJOY', 'ENTER',
            'ENTRY', 'EQUAL', 'ERROR', 'EVENT', 'EVERY', 'EXACT', 'EXIST', 'EXTRA',
            'FAITH', 'FALSE', 'FAULT', 'FIBER', 'FIELD', 'FIFTH', 'FIFTY', 'FIGHT',
            'FINAL', 'FIRST', 'FIXED', 'FLASH', 'FLEET', 'FLOOR', 'FLUID', 'FOCUS',
            'FORCE', 'FORTH', 'FORTY', 'FORUM', 'FOUND', 'FRAME', 'FRANK', 'FRAUD',
            'FRESH', 'FRONT', 'FROST', 'FRUIT', 'FULLY', 'FUNNY', 'GIANT', 'GIVEN',
            'GLASS', 'GLOBE', 'GOING', 'GRACE', 'GRADE', 'GRAND', 'GRANT', 'GRASS',
            'GRAVE', 'GREAT', 'GREEN', 'GROSS', 'GROUP', 'GROWN', 'GUARD', 'GUESS',
            'GUEST', 'GUIDE', 'HAPPY', 'HARRY', 'HEART', 'HEAVY', 'HORSE', 'HOTEL',
            'HOUSE', 'HUMAN', 'IDEAL', 'IMAGE', 'INDEX', 'INNER', 'INPUT', 'ISSUE',
            'JAPAN', 'JIMMY', 'JOINT', 'JONES', 'JUDGE', 'KNOWN', 'LABEL', 'LARGE',
            'LASER', 'LATER', 'LAUGH', 'LAYER', 'LEARN', 'LEASE', 'LEAST', 'LEAVE',
            'LEGAL', 'LEVEL', 'LEWIS', 'LIGHT', 'LIMIT', 'LINKS', 'LIVES', 'LOCAL',
            'LOOSE', 'LOWER', 'LUCKY', 'LUNCH', 'LYING', 'MAGIC', 'MAJOR', 'MAKER',
            'MARCH', 'MARIA', 'MATCH', 'MAYBE', 'MAYOR', 'MEANT', 'MEDIA', 'METAL',
            'MIGHT', 'MINOR', 'MINUS', 'MIXED', 'MODEL', 'MONEY', 'MONTH', 'MORAL',
            'MOTOR', 'MOUNT', 'MOUSE', 'MOUTH', 'MOVED', 'MOVIE', 'MUSIC', 'NEEDS',
            'NEVER', 'NEWLY', 'NIGHT', 'NOISE', 'NORTH', 'NOTED', 'NOVEL', 'NURSE',
            'OCCUR', 'OCEAN', 'OFFER', 'OFTEN', 'ORDER', 'OTHER', 'OUGHT', 'PAINT',
            'PANEL', 'PAPER', 'PARTY', 'PEACE', 'PETER', 'PHASE', 'PHONE', 'PHOTO',
            'PIANO', 'PIECE', 'PILOT', 'PITCH', 'PLACE', 'PLAIN', 'PLANE', 'PLANT',
            'PLATE', 'PLAZA', 'PLOT', 'PLUG', 'PLUS', 'POINT', 'POUND', 'POWER',
            'PRESS', 'PRICE', 'PRIDE', 'PRIME', 'PRINT', 'PRIOR', 'PRIZE', 'PROOF',
            'PROUD', 'PROVE', 'QUEEN', 'QUICK', 'QUIET', 'QUITE', 'RADIO', 'RAISE',
            'RANGE', 'RAPID', 'RATIO', 'REACH', 'READY', 'REALM', 'REBEL', 'REFER',
            'RELAX', 'REPAY', 'REPLY', 'RIGHT', 'RIGID', 'RIVER', 'ROBIN', 'ROGER',
            'ROMAN', 'ROUGH', 'ROUND', 'ROUTE', 'ROYAL', 'RURAL', 'SCALE', 'SCENE',
            'SCOPE', 'SCORE', 'SENSE', 'SERVE', 'SETUP', 'SEVEN', 'SHALL', 'SHAPE',
            'SHARE', 'SHARP', 'SHEET', 'SHELF', 'SHELL', 'SHIFT', 'SHINE', 'SHIRT',
            'SHOCK', 'SHOOT', 'SHORT', 'SHOWN', 'SIDED', 'SIGHT', 'SILLY', 'SINCE',
            'SIXTY', 'SIZED', 'SKILL', 'SLEEP', 'SLIDE', 'SMALL', 'SMART', 'SMILE',
            'SMITH', 'SMOKE', 'SNAKE', 'SNOW', 'SOLAR', 'SOLID', 'SOLVE', 'SORRY',
            'SOUND', 'SOUTH', 'SPACE', 'SPARE', 'SPEAK', 'SPEED', 'SPEND', 'SPENT',
            'SPLIT', 'SPOKE', 'SPORT', 'STAFF', 'STAGE', 'STAKE', 'STAND', 'START',
            'STATE', 'STEAM', 'STEEL', 'STEEP', 'STEER', 'STEPS', 'STICK', 'STILL',
            'STOCK', 'STONE', 'STOOD', 'STORE', 'STORM', 'STORY', 'STRIP', 'STUCK',
            'STUDY', 'STUFF', 'STYLE', 'SUGAR', 'SUITE', 'SUPER', 'SWEET', 'TABLE',
            'TAKEN', 'TASTE', 'TAXES', 'TEACH', 'TEETH', 'TERRY', 'TEXAS', 'THANK',
            'THEFT', 'THEIR', 'THEME', 'THERE', 'THESE', 'THICK', 'THING', 'THINK',
            'THIRD', 'THOSE', 'THREE', 'THREW', 'THROW', 'THUMB', 'TIGHT', 'TIMED',
            'TIMER', 'TIMES', 'TITLE', 'TODAY', 'TOPIC', 'TOTAL', 'TOUCH', 'TOUGH',
            'TOWER', 'TRACK', 'TRADE', 'TRAIN', 'TREAT', 'TREND', 'TRIAL', 'TRIBE',
            'TRICK', 'TRIED', 'TRIES', 'TRIPS', 'TRULY', 'TRUNK', 'TRUST', 'TRUTH',
            'TWICE', 'TWIST', 'TYLER', 'TYPES', 'UNCLE', 'UNDER', 'UNDUE', 'UNION',
            'UNITY', 'UNTIL', 'UPPER', 'UPSET', 'URBAN', 'USAGE', 'USUAL', 'VALID',
            'VALUE', 'VIDEO', 'VIRUS', 'VISIT', 'VITAL', 'VOCAL', 'WASTE', 'WATCH',
            'WATER', 'WAVES', 'WAYS', 'WEIRD', 'WELSH', 'WHEEL', 'WHERE', 'WHICH',
            'WHILE', 'WHITE', 'WHOLE', 'WHOSE', 'WOMAN', 'WOMEN', 'WORLD', 'WORRY',
            'WORSE', 'WORST', 'WORTH', 'WOULD', 'WRITE', 'WRONG', 'WROTE', 'YOUNG',
            'YOUTH', 'ZEBRA', 'ZEROS', 'ZONES'
        ];
        
        this.initializeGame();
    }
    
    initializeGame() {
        this.createGameBoard();
        this.setupEventListeners();
        this.gameStarted = true;
    }
    
    createGameBoard() {
        const gameBoard = document.getElementById('gameBoard');
        gameBoard.innerHTML = '';
        
        for (let row = 0; row < this.maxGuesses; row++) {
            const rowElement = document.createElement('div');
            rowElement.className = 'game-row';
            rowElement.id = `row-${row}`;
            
            for (let col = 0; col < this.wordLength; col++) {
                const tile = document.createElement('div');
                tile.className = 'tile';
                tile.id = `tile-${row}-${col}`;
                rowElement.appendChild(tile);
            }
            
            gameBoard.appendChild(rowElement);
        }
    }
    
    setupEventListeners() {
        // Keyboard event listeners
        document.addEventListener('keydown', (e) => this.handleKeyPress(e));
        
        // Virtual keyboard event listeners
        document.querySelectorAll('.key').forEach(key => {
            key.addEventListener('click', () => {
                const keyValue = key.dataset.key;
                this.handleKeyPress({ key: keyValue });
            });
        });
        
        // All button event listeners
        this.setupAllButtonListeners();
    }
    
    setupAllButtonListeners() {
        // Solver button
        document.getElementById('solverBtn').addEventListener('click', () => {
            this.toggleSolverPanel();
        });
        
        document.getElementById('closeSolver').addEventListener('click', () => {
            this.hideSolverPanel();
        });
        
        // Solver control buttons
        document.getElementById('useSuggestion').addEventListener('click', () => {
            this.useSolverSuggestion();
        });
        
        document.getElementById('getHint').addEventListener('click', () => {
            this.getSolverHint();
        });
        
        document.getElementById('analyzeBoard').addEventListener('click', () => {
            this.analyzeBoard();
        });
        
        // Modal buttons
        document.getElementById('helpBtn').addEventListener('click', () => {
            this.showHelpModal();
        });
        
        document.getElementById('helpClose').addEventListener('click', () => {
            this.hideHelpModal();
        });
        
        document.getElementById('statsBtn').addEventListener('click', () => {
            this.showStatsModal();
        });
        
        document.getElementById('statsClose').addEventListener('click', () => {
            this.hideStatsModal();
        });
        
        document.getElementById('settingsBtn').addEventListener('click', () => {
            this.showSettingsModal();
        });
        
        document.getElementById('settingsClose').addEventListener('click', () => {
            this.hideSettingsModal();
        });
        
        // Settings toggles
        document.getElementById('darkMode').addEventListener('change', (e) => {
            this.toggleDarkMode(e.target.checked);
        });
        
        document.getElementById('colorBlind').addEventListener('change', (e) => {
            this.toggleColorBlindMode(e.target.checked);
        });
        
        document.getElementById('hardMode').addEventListener('change', (e) => {
            this.toggleHardMode(e.target.checked);
        });
        
        // Demo buttons (will be added after DOM loads)
        const demoBtn = document.getElementById('demoBtn');
        const newGameBtn = document.getElementById('newGameBtn');
        
        if (demoBtn) {
            demoBtn.addEventListener('click', () => {
                this.runDemo();
            });
        }
        
        if (newGameBtn) {
            newGameBtn.addEventListener('click', () => {
                this.startNewGame();
            });
        }
        
        // Close modals when clicking outside
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    modal.classList.remove('show');
                }
            });
        });
        
        // Load saved settings
        this.loadSettings();
    }
    
    // Core game logic
    handleKeyPress(e) {
        if (!this.gameStarted || this.gameOver) return;
        
        const key = e.key.toUpperCase();
        
        if (key === 'ENTER') {
            this.submitGuess();
        } else if (key === 'BACKSPACE') {
            this.deleteLetter();
        } else if (key.length === 1 && key >= 'A' && key <= 'Z') {
            this.addLetter(key);
        }
    }
    
    addLetter(letter) {
        if (this.currentGuess.length < this.wordLength) {
            this.currentGuess += letter;
            this.updateCurrentRow();
        }
    }
    
    deleteLetter() {
        if (this.currentGuess.length > 0) {
            this.currentGuess = this.currentGuess.slice(0, -1);
            this.updateCurrentRow();
        }
    }
    
    updateCurrentRow() {
        const rowElement = document.getElementById(`row-${this.currentRow}`);
        const tiles = rowElement.querySelectorAll('.tile');
        
        tiles.forEach((tile, index) => {
            // Only update tiles that haven't been evaluated yet
            if (!tile.classList.contains('correct') && 
                !tile.classList.contains('present') && 
                !tile.classList.contains('absent')) {
                
                if (index < this.currentGuess.length) {
                    tile.textContent = this.currentGuess[index];
                    tile.classList.add('filled');
                } else {
                    tile.textContent = '';
                    tile.classList.remove('filled');
                }
            }
        });
    }
    
    submitGuess() {
        console.log('Submitting guess:', this.currentGuess);
        
        if (!this.gameStarted || this.gameOver) return;
        
        if (this.currentGuess.length !== this.wordLength) {
            this.showMessage('Not enough letters', 'error');
            return;
        }
        
        if (!this.isValidWord(this.currentGuess)) {
            console.log('Invalid word:', this.currentGuess);
            this.showMessage('Not a valid word', 'error');
            this.shakeCurrentRow();
            return;
        }
        
        console.log('Valid word, proceeding with evaluation');
        
        // Evaluate the guess
        const evaluation = this.evaluateGuess(this.currentGuess, this.secretWord);
        
        // Store guess and feedback
        this.guesses.push(this.currentGuess);
        this.feedback.push(evaluation);
        
        // Apply evaluation to tiles
        this.applyEvaluation(evaluation);
        
        // Update keyboard colors
        this.updateKeyboardColors(this.currentGuess, evaluation);
        
        // Check if won
        if (evaluation.every(status => status === 'correct')) {
            this.gameWon = true;
            this.gameOver = true;
            this.showMessage('Congratulations! You won!', 'success');
            this.updateStats(true);
            return;
        }
        
        // Move to next row
        this.currentRow++;
        this.currentGuess = '';
        
        // Check if game over
        if (this.currentRow >= this.maxGuesses) {
            this.gameOver = true;
            this.showMessage(`Game over! The word was ${this.secretWord}`, 'error');
            this.updateStats(false);
        }
        
        // Update solver display if panel is open
        if (document.getElementById('solverPanel').classList.contains('show')) {
            this.updateSolverDisplay();
        }
    }
    
    isValidWord(word) {
        return this.wordList.includes(word);
    }
    
    evaluateGuess(guess, secret) {
        const evaluation = new Array(this.wordLength).fill('absent');
        const secretLetters = {};
        
        // Count letter frequencies in secret word
        for (let i = 0; i < secret.length; i++) {
            secretLetters[secret[i]] = (secretLetters[secret[i]] || 0) + 1;
        }
        
        // First pass: mark correct letters (green)
        for (let i = 0; i < guess.length; i++) {
            if (guess[i] === secret[i]) {
                evaluation[i] = 'correct';
                secretLetters[secret[i]]--;
            }
        }
        
        // Second pass: mark present letters (yellow)
        for (let i = 0; i < guess.length; i++) {
            if (evaluation[i] === 'absent' && secretLetters[guess[i]] > 0) {
                evaluation[i] = 'present';
                secretLetters[guess[i]]--;
            }
        }
        
        return evaluation;
    }
    
    applyEvaluation(evaluation) {
        const rowElement = document.getElementById(`row-${this.currentRow}`);
        const tiles = rowElement.querySelectorAll('.tile');
        
        tiles.forEach((tile, index) => {
            setTimeout(() => {
                // Remove any existing state classes
                tile.classList.remove('correct', 'present', 'absent');
                // Add the new state class
                tile.classList.add(evaluation[index]);
            }, index * 200);
        });
    }
    
    updateKeyboardColors(guess, evaluation) {
        guess.split('').forEach((letter, index) => {
            const key = document.querySelector(`[data-key="${letter}"]`);
            if (key) {
                const status = evaluation[index];
                
                // Only update if current status is better than existing
                if (!key.classList.contains('correct') && 
                    (!key.classList.contains('present') || status === 'correct')) {
                    key.classList.remove('present', 'absent');
                    key.classList.add(status);
                }
            }
        });
    }
    
    shakeCurrentRow() {
        const rowElement = document.getElementById(`row-${this.currentRow}`);
        const tiles = rowElement.querySelectorAll('.tile');
        
        tiles.forEach(tile => {
            tile.classList.add('wrong');
            setTimeout(() => {
                tile.classList.remove('wrong');
            }, 500);
        });
    }
    
    showMessage(message, type = 'info') {
        const statusElement = document.getElementById('gameStatus');
        statusElement.textContent = message;
        statusElement.className = `game-status ${type}`;
        
        // Clear message after 3 seconds
        setTimeout(() => {
            statusElement.textContent = '';
            statusElement.className = 'game-status';
        }, 3000);
    }
    
    // Solver functionality
    toggleSolverPanel() {
        const panel = document.getElementById('solverPanel');
        panel.classList.toggle('show');
        
        if (panel.classList.contains('show')) {
            this.updateSolverDisplay();
        }
    }
    
    hideSolverPanel() {
        document.getElementById('solverPanel').classList.remove('show');
    }
    
    updateSolverDisplay() {
        const suggestedWord = this.getOptimalWord();
        const possibleWords = this.getPossibleWords();
        const confidence = this.getConfidence(possibleWords);
        
        document.getElementById('suggestedWord').textContent = suggestedWord;
        document.getElementById('remainingWords').textContent = possibleWords.length.toLocaleString();
        document.getElementById('solverConfidence').textContent = `${confidence}%`;
        
        // Update suggestion reason
        let reason = '';
        if (this.guesses.length === 0) {
            reason = 'Optimal starting word with high-frequency letters';
        } else if (possibleWords.length <= 5) {
            reason = 'High confidence - very few possibilities remain';
        } else if (possibleWords.length <= 20) {
            reason = 'Good elimination potential';
        } else {
            reason = 'Focusing on common letter patterns';
        }
        document.getElementById('suggestionReason').textContent = reason;
    }
    
    useSolverSuggestion() {
        if (this.gameOver) {
            this.showMessage('Game is over! Click "New Game" to start again.', 'info');
            return;
        }
        
        const suggestion = document.getElementById('suggestedWord').textContent;
        this.currentGuess = suggestion;
        this.updateCurrentRow();
        this.showMessage(`Using solver suggestion: ${suggestion}`, 'info');
    }
    
    getSolverHint() {
        const possibleWords = this.getPossibleWords();
        if (possibleWords.length === 0) {
            this.showMessage('Solver hint: No valid words remaining!', 'info');
            return;
        }
        if (possibleWords.length === 1) {
            this.showMessage(`Solver hint: The word is ${possibleWords[0]}`, 'info');
            return;
        }
        
        const commonLetters = this.findCommonLetters(possibleWords);
        const hint = `Try using letters: ${commonLetters.join(', ')}`;
        this.showMessage(`Solver hint: ${hint}`, 'info');
    }
    
    analyzeBoard() {
        const possibleWords = this.getPossibleWords();
        const analysis = this.getBoardAnalysis(possibleWords);
        this.showMessage(`Board analysis: ${analysis}`, 'info');
    }
    
    getBoardAnalysis(possibleWords) {
        if (possibleWords.length === 0) return "No valid words remaining!";
        if (possibleWords.length === 1) return `Only one possibility: ${possibleWords[0]}`;
        if (possibleWords.length <= 5) return `Very close! Only ${possibleWords.length} possibilities left`;
        if (possibleWords.length <= 20) return `Good progress! ${possibleWords.length} possibilities remain`;
        return `${possibleWords.length} possibilities still open - keep eliminating letters`;
    }
    
    getOptimalWord() {
        if (this.guesses.length === 0) {
            return ['CRANE', 'SLATE', 'ADIEU', 'AUDIO', 'RAISE'][Math.floor(Math.random() * 5)];
        }
        
        const possibleWords = this.getPossibleWords();
        if (possibleWords.length === 0) return 'ERROR';
        if (possibleWords.length === 1) return possibleWords[0];
        
        // Simple scoring based on letter frequency
        const letterFrequency = this.calculateLetterFrequency();
        const scoredWords = possibleWords.map(word => ({
            word,
            score: this.scoreWord(word, letterFrequency)
        }));
        
        scoredWords.sort((a, b) => b.score - a.score);
        return scoredWords[0].word;
    }
    
    getPossibleWords() {
        let possibleWords = [...this.wordList];
        
        for (let i = 0; i < this.guesses.length; i++) {
            const guess = this.guesses[i];
            const feedback = this.feedback[i];
            possibleWords = this.filterWords(possibleWords, guess, feedback);
        }
        
        return possibleWords;
    }
    
    filterWords(words, guess, feedback) {
        return words.filter(word => {
            const wordArray = word.split('');
            const guessArray = guess.split('');
            
            // Check each position
            for (let i = 0; i < 5; i++) {
                const feedbackType = feedback[i];
                const guessLetter = guessArray[i];
                const wordLetter = wordArray[i];
                
                if (feedbackType === 'correct') {
                    if (wordLetter !== guessLetter) return false;
                } else if (feedbackType === 'present') {
                    if (wordLetter === guessLetter) return false; // Can't be in same position
                    if (!wordArray.includes(guessLetter)) return false; // Must contain letter
                } else if (feedbackType === 'absent') {
                    if (wordArray.includes(guessLetter)) return false; // Can't contain letter
                }
            }
            
            return true;
        });
    }
    
    calculateLetterFrequency() {
        const frequency = {};
        this.wordList.forEach(word => {
            word.split('').forEach(letter => {
                frequency[letter] = (frequency[letter] || 0) + 1;
            });
        });
        return frequency;
    }
    
    scoreWord(word, letterFrequency) {
        let score = 0;
        const letters = new Set(word.split(''));
        
        letters.forEach(letter => {
            score += letterFrequency[letter] || 0;
        });
        
        return score;
    }
    
    getConfidence(possibleWords) {
        if (possibleWords.length <= 1) return 100;
        if (possibleWords.length <= 5) return 90;
        if (possibleWords.length <= 20) return 75;
        if (possibleWords.length <= 100) return 60;
        return 40;
    }
    
    findCommonLetters(words) {
        const letterCount = {};
        words.forEach(word => {
            word.split('').forEach(letter => {
                letterCount[letter] = (letterCount[letter] || 0) + 1;
            });
        });
        
        return Object.entries(letterCount)
            .filter(([letter, count]) => count > words.length * 0.3)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 5)
            .map(([letter]) => letter);
    }
    
    // Modal functionality
    showHelpModal() {
        document.getElementById('helpModal').classList.add('show');
    }
    
    hideHelpModal() {
        document.getElementById('helpModal').classList.remove('show');
    }
    
    showStatsModal() {
        this.updateStatsDisplay();
        document.getElementById('statsModal').classList.add('show');
    }
    
    hideStatsModal() {
        document.getElementById('statsModal').classList.remove('show');
    }
    
    showSettingsModal() {
        document.getElementById('settingsModal').classList.add('show');
    }
    
    hideSettingsModal() {
        document.getElementById('settingsModal').classList.remove('show');
    }
    
    // Settings functionality
    toggleDarkMode(enabled) {
        document.body.classList.toggle('dark', enabled);
        localStorage.setItem('darkMode', enabled);
    }
    
    toggleColorBlindMode(enabled) {
        document.body.classList.toggle('colorblind', enabled);
        localStorage.setItem('colorBlind', enabled);
    }
    
    toggleHardMode(enabled) {
        localStorage.setItem('hardMode', enabled);
        this.showMessage(enabled ? 'Hard mode enabled' : 'Hard mode disabled', 'info');
    }
    
    loadSettings() {
        const darkMode = localStorage.getItem('darkMode') === 'true';
        const colorBlind = localStorage.getItem('colorBlind') === 'true';
        const hardMode = localStorage.getItem('hardMode') === 'true';
        
        document.getElementById('darkMode').checked = darkMode;
        document.getElementById('colorBlind').checked = colorBlind;
        document.getElementById('hardMode').checked = hardMode;
        
        document.body.classList.toggle('dark', darkMode);
        document.body.classList.toggle('colorblind', colorBlind);
    }
    
    // Stats functionality
    updateStats(won) {
        const stats = this.getStats();
        stats.gamesPlayed++;
        if (won) {
            stats.gamesWon++;
            stats.currentStreak++;
            stats.maxStreak = Math.max(stats.maxStreak, stats.currentStreak);
        } else {
            stats.currentStreak = 0;
        }
        stats.winRate = Math.round((stats.gamesWon / stats.gamesPlayed) * 100);
        
        // Update guess distribution
        if (won) {
            stats.guessDistribution[this.guesses.length - 1]++;
        }
        
        localStorage.setItem('wordleStats', JSON.stringify(stats));
    }
    
    getStats() {
        const defaultStats = {
            gamesPlayed: 0,
            gamesWon: 0,
            winRate: 0,
            currentStreak: 0,
            maxStreak: 0,
            guessDistribution: [0, 0, 0, 0, 0, 0]
        };
        
        const savedStats = localStorage.getItem('wordleStats');
        return savedStats ? JSON.parse(savedStats) : defaultStats;
    }
    
    updateStatsDisplay() {
        const stats = this.getStats();
        
        document.querySelector('.stats-grid .stat-item:nth-child(1) .stat-number').textContent = stats.gamesPlayed;
        document.querySelector('.stats-grid .stat-item:nth-child(2) .stat-number').textContent = `${stats.winRate}%`;
        document.querySelector('.stats-grid .stat-item:nth-child(3) .stat-number').textContent = stats.currentStreak;
        document.querySelector('.stats-grid .stat-item:nth-child(4) .stat-number').textContent = stats.maxStreak;
        
        // Update guess distribution bars
        const maxGuesses = Math.max(...stats.guessDistribution);
        stats.guessDistribution.forEach((count, index) => {
            const bar = document.querySelector(`.distribution-bar:nth-child(${index + 2}) .bar`);
            const barCount = document.querySelector(`.distribution-bar:nth-child(${index + 2}) .bar-count`);
            
            if (bar && barCount) {
                const percentage = maxGuesses > 0 ? (count / maxGuesses) * 100 : 0;
                bar.style.width = `${percentage}%`;
                barCount.textContent = count;
            }
        });
    }
    
    // Game control functionality
    startNewGame() {
        this.currentGuess = '';
        this.currentRow = 0;
        this.gameOver = false;
        this.gameWon = false;
        this.guesses = [];
        this.feedback = [];
        this.gameStarted = true;
        
        // Keep RIVER as the answer for consistent testing
        this.secretWord = 'RIVER';
        
        this.createGameBoard();
        this.updateKeyboard();
        this.hideSolverPanel();
        this.showMessage('New game started!', 'info');
    }
    
    runDemo() {
        if (this.gameOver) {
            this.showMessage('Game is over! Click "New Game" to start again.', 'info');
            return;
        }
        
        // Demo with the word "CRANE" (good starting word)
        const demoWord = 'CRANE';
        let letterIndex = 0;
        
        const addNextLetter = () => {
            if (letterIndex < demoWord.length) {
                this.addLetter(demoWord[letterIndex]);
                letterIndex++;
                setTimeout(addNextLetter, 300);
            } else {
                setTimeout(() => {
                    this.submitGuess();
                }, 500);
            }
        };
        
        addNextLetter();
    }
    
    updateKeyboard() {
        // Reset keyboard colors
        document.querySelectorAll('.key').forEach(key => {
            key.classList.remove('correct', 'present', 'absent');
        });
    }
}

// Initialize the game when the page loads
document.addEventListener('DOMContentLoaded', () => {
    const game = new WordleGameBackend();
    
    // Add demo buttons
    const header = document.querySelector('.header');
    const demoControls = document.createElement('div');
    demoControls.className = 'demo-controls';
    demoControls.innerHTML = `
        <button class="btn btn-demo" id="demoBtn">Demo</button>
        <button class="btn btn-demo" id="newGameBtn">New Game</button>
    `;
    header.appendChild(demoControls);
    
    // Now add event listeners for the demo buttons
    document.getElementById('demoBtn').addEventListener('click', () => {
        game.runDemo();
    });
    
    document.getElementById('newGameBtn').addEventListener('click', () => {
        game.startNewGame();
    });
});

// Add CSS for demo buttons
const demoStyles = `
.demo-controls {
    display: flex;
    gap: 12px;
    margin-left: 20px;
}

.btn-demo {
    background: linear-gradient(45deg, #3b82f6, #10b981);
    color: white;
    font-size: 0.9rem;
    padding: 8px 16px;
    border: none;
}

.btn-demo:hover {
    background: linear-gradient(45deg, #2563eb, #059669);
}

body.dark .btn-demo {
    background: linear-gradient(45deg, #3b82f6, #10b981);
}

body.dark .btn-demo:hover {
    background: linear-gradient(45deg, #2563eb, #059669);
}
`;

// Inject demo styles
const styleSheet = document.createElement('style');
styleSheet.textContent = demoStyles;
document.head.appendChild(styleSheet);
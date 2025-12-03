class WordleApp {
    constructor() {
        this.state = {
            board: [],
            currentGuess: '',
            gameOver: false,
            wordLength: 5,
            keyboardState: {}, 
            hints: [], 
            config: {
                wordLength: 5,
                maxGuesses: 6,
                showHints: true,
                feedbackMode: 'standard',
                showDistances: false
            }
        };

        this.init();
    }

    init() {
        // Event Listeners
        document.getElementById('newGameBtn').onclick = () => this.showSettings(); 
        document.getElementById('startGameBtn').onclick = () => {
            this.applySettings();
            this.startNewGame();
            this.hideSettings();
        };
        
        // Close button handler (cross out) - Just closes modal, resumes game
        document.getElementById('settingsClose').onclick = () => this.hideSettings();

        // Global hint request function
        window.requestHint = (mode) => this.requestHint(mode);

        document.addEventListener('keydown', (e) => this.handleKey(e));
        this.renderKeyboard();
        
        // Show configuration modal on load
        this.showSettings();
    }

    async startNewGame() {
        try {
            const res = await fetch('/api/new-game', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(this.state.config)
            });
            const data = await res.json();
            
            if (data.status === 'success') {
                this.state.board = [];
                this.state.currentGuess = '';
                this.state.gameOver = false;
                this.state.keyboardState = {};
                this.state.hints = [];
                this.state.wordLength = this.state.config.wordLength;
                
                this.renderBoard();
                this.renderKeyboard();
                this.updateStatus("New game started!");
                this.updateSolverPanel(null);
                this.updateHintDisplay();
                
                // Show/Hide hint controls based on config, even if solver is hidden
                // Decouple: hint buttons always visible if showHints is enabled, 
                // regardless of solver panel state (though solver panel is also tied to showHints currently).
                // Requirement: "If i disable solver in setting, the two hint buttons should still be there"
                // Let's check if there is a separate setting for solver vs hints.
                // Currently config has `showHints`. We might interpret this as "Show Solver Hints".
                // The user said "hint buttons shouldn't be tied to solver". 
                // We'll make hint controls always visible for now, or add a separate toggle if needed.
                // For now, let's just make them visible by default.
                document.getElementById('hintControls').style.display = 'flex';
                
                // Solver panel visibility still controlled by config
                if (this.state.config.showHints) {
                    // Solver panel will show when data is available
                } else {
                    document.getElementById('solverPanel').classList.remove('visible');
                }
            }
        } catch (e) {
            console.error("Failed to start game", e);
        }
    }

    async submitGuess() {
        if (this.state.gameOver) return;
        if (this.state.currentGuess.length !== this.state.wordLength) {
            this.updateStatus("Too short!");
            return;
        }

        try {
            const res = await fetch('/api/guess', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ guess: this.state.currentGuess })
            });
            const data = await res.json();

            if (data.status === 'error') {
                this.updateStatus(data.message);
                return;
            }

            this.state.board.push(data.feedback);
            this.state.currentGuess = '';
            
            this.updateKeyboardState(data.feedback);
            this.renderBoard();
            this.renderKeyboard();

            if (data.isWon) {
                this.state.gameOver = true;
                this.updateStatus("🎉 You Won!");
            } else if (data.isOver) {
                this.state.gameOver = true;
                this.updateStatus(`Game Over! Answer: ${data.answer}`);
            } else {
                this.updateStatus(`Guess ${this.state.board.length}/${this.state.config.maxGuesses}`);
            }

            if (data.solverHint) {
                this.updateSolverPanel(data);
            }

        } catch (e) {
            console.error("Error submitting guess", e);
        }
    }

    async requestHint(mode) {
        if (this.state.gameOver) return;
        
        // Prevent default focus behavior that might cause Enter to re-trigger
        if (document.activeElement) {
            document.activeElement.blur();
        }
        
        try {
            const res = await fetch('/api/hint', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ mode })
            });
            const data = await res.json();
            
            if (data.status === 'success') {
                let hintText = '';
                if (data.type === 'position') {
                    hintText = `Position ${data.pos + 1}: ${data.letter}`;
                } else {
                    hintText = `Letter in word: ${data.letter}`;
                }
                
                this.state.hints.push(hintText);
                this.updateHintDisplay();
            }
        } catch (e) {
            console.error("Error requesting hint", e);
        }
    }

    updateHintDisplay() {
        const container = document.getElementById('hintDisplay');
        if (this.state.hints.length === 0) {
            container.innerHTML = '';
            container.style.display = 'none';
        } else {
            container.style.display = 'flex';
            container.innerHTML = this.state.hints.map(h => `<div class="hint-tag">${h}</div>`).join('');
        }
    }

    handleKey(e) {
        // Prevent typing if modal is open
        if (document.getElementById('settingsModal').classList.contains('show')) return;
        if (this.state.gameOver) return;

        const key = e.key.toUpperCase();
        
        if (key === 'ENTER') {
            e.preventDefault(); // Prevent button click if focused
            this.submitGuess();
        } else if (key === 'BACKSPACE') {
            this.state.currentGuess = this.state.currentGuess.slice(0, -1);
            this.renderCurrentRow();
        } else if (/^[A-Z]$/.test(key) && this.state.currentGuess.length < this.state.wordLength) {
            this.state.currentGuess += key;
            this.renderCurrentRow();
        }
    }

    updateKeyboardState(feedback) {
        feedback.colors.forEach((color, idx) => {
            const letter = feedback.guess[idx].toUpperCase(); 
            const current = this.state.keyboardState[letter];
            if (color === 'correct') {
                this.state.keyboardState[letter] = 'correct';
            } else if (color === 'present' && current !== 'correct') {
                this.state.keyboardState[letter] = 'present';
            } else if (color === 'absent' && !current) {
                this.state.keyboardState[letter] = 'absent';
            }
        });
    }

    updateSolverPanel(data) {
        const panel = document.getElementById('solverPanel');
        if (!this.state.config.showHints) {
            panel.classList.remove('visible');
            return;
        }

        if (data) {
            panel.classList.add('visible');
            document.getElementById('solverHint').textContent = data.solverHint;
            document.getElementById('candidateCount').textContent = data.candidates;
        } else {
            document.getElementById('solverHint').textContent = '-';
            document.getElementById('candidateCount').textContent = '-';
        }
    }

    renderBoard() {
        const boardEl = document.getElementById('gameBoard');
        boardEl.innerHTML = '';

        this.state.board.forEach(fb => {
            const row = document.createElement('div');
            row.className = 'row';
            
            fb.guess.split('').forEach((char, i) => {
                const tile = document.createElement('div');
                tile.className = `tile ${fb.colors[i]}`;
                tile.textContent = char.toUpperCase();
                
                if (this.state.config.showDistances && fb.distances && fb.distances[i] !== null) {
                    const dist = fb.distances[i];
                    const distSpan = document.createElement('span');
                    distSpan.className = 'distance-indicator';
                    distSpan.textContent = dist > 0 ? `+${dist}` : dist;
                    tile.appendChild(distSpan);
                }
                
                row.appendChild(tile);
            });
            boardEl.appendChild(row);
        });

        if (!this.state.gameOver && this.state.board.length < this.state.config.maxGuesses) {
            const row = document.createElement('div');
            row.className = 'row current';
            
            for (let i = 0; i < this.state.wordLength; i++) {
                const tile = document.createElement('div');
                tile.className = 'tile';
                tile.textContent = this.state.currentGuess[i] || '';
                if (this.state.currentGuess[i]) tile.classList.add('filled');
                row.appendChild(tile);
            }
            boardEl.appendChild(row);
        }

        const remaining = this.state.config.maxGuesses - this.state.board.length - (this.state.gameOver ? 0 : 1);
        for (let r = 0; r < remaining; r++) {
            const row = document.createElement('div');
            row.className = 'row';
            for (let i = 0; i < this.state.wordLength; i++) {
                const tile = document.createElement('div');
                tile.className = 'tile';
                row.appendChild(tile);
            }
            boardEl.appendChild(row);
        }
    }

    renderCurrentRow() {
        const currentRows = document.querySelectorAll('.row.current .tile');
        if (currentRows.length === 0) return;
        
        currentRows.forEach((tile, i) => {
            const char = this.state.currentGuess[i] || '';
            tile.textContent = char;
            if (char) tile.classList.add('filled');
            else tile.classList.remove('filled');
        });
    }

    renderKeyboard() {
        const layout = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
        const keyboardEl = document.getElementById('keyboard');
        keyboardEl.innerHTML = '';
        
        layout.forEach(rowStr => {
            const rowEl = document.createElement('div');
            rowEl.className = 'key-row';
            rowStr.split('').forEach(char => {
                const key = document.createElement('button');
                key.className = `key ${this.state.keyboardState[char] || ''}`;
                key.textContent = char;
                key.onclick = (e) => {
                    e.target.blur(); // Remove focus so Enter doesn't re-trigger
                    this.handleKey({ key: char });
                };
                rowEl.appendChild(key);
            });
            if (rowStr === 'ZXCVBNM') {
                const enter = document.createElement('button');
                enter.className = 'key wide';
                enter.textContent = 'ENTER';
                enter.onclick = (e) => {
                    e.target.blur();
                    this.submitGuess();
                };
                const back = document.createElement('button');
                back.className = 'key wide';
                back.textContent = '⌫';
                back.onclick = (e) => {
                    e.target.blur();
                    this.handleKey({ key: 'BACKSPACE' });
                };
                rowEl.insertBefore(enter, rowEl.firstChild);
                rowEl.appendChild(back);
            }
            keyboardEl.appendChild(rowEl);
        });
    }

    updateStatus(msg) {
        document.getElementById('gameStatus').textContent = msg;
    }

    showSettings() {
        document.getElementById('settingsModal').classList.add('show');
    }

    hideSettings() {
        document.getElementById('settingsModal').classList.remove('show');
    }

    applySettings() {
        this.state.config = {
            wordLength: parseInt(document.getElementById('wordLength').value),
            maxGuesses: parseInt(document.getElementById('maxGuesses').value),
            feedbackMode: document.getElementById('feedbackMode').value,
            showHints: document.getElementById('showHints').checked,
            showDistances: document.getElementById('showDistances').checked
        };
    }
}

window.onload = () => new WordleApp();

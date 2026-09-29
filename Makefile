# ==============================================================================
# Makefile Generale per rrdespike (Ada, Rust, Go, C)
# ==============================================================================

BIN_DIR := bin

# Nomi degli eseguibili finali nella cartella bin/
ADA_BIN  := $(BIN_DIR)/rrdespike-ada
RS_BIN   := $(BIN_DIR)/rrdespike-rs
GO_BIN   := $(BIN_DIR)/rrdespike-go
CC_BIN   := $(BIN_DIR)/rrdespike-cc

# Compilatori e Toolchain
ALR      := alr
CARGO    := cargo
GO       := go
CC       := gcc
CFLAGS   := -Wall -Wextra -O2 -std=c99
LDFLAGS  := -lm

.PHONY: all ada rust go c clean help

# Target predefinito: compila tutte e 4 le varianti
all: ada rust go c

# ------------------------------------------------------------------------------
# 1. Variante Ada (tramite Alire)
# ------------------------------------------------------------------------------
ada: $(ADA_BIN)

$(ADA_BIN): | $(BIN_DIR)
	@echo "===> Compilazione versione Ada..."
	@cd ada && $(ALR) build --release
	@cp -f ada/bin/main $@ 2>/dev/null || cp -f ada/obj/main $@ 2>/dev/null || cp -f ada/main $@ $@
	@echo "OK: Generato $@"

# ------------------------------------------------------------------------------
# 2. Variante Rust (tramite Cargo)
# ------------------------------------------------------------------------------
rust: $(RS_BIN)

$(RS_BIN): | $(BIN_DIR)
	@echo "===> Compilazione versione Rust..."
	@cd rust && $(CARGO) build --release
	@cp -f rust/target/release/rrdespike $@
	@echo "OK: Generato $@"

# ------------------------------------------------------------------------------
# 3. Variante Go
# ------------------------------------------------------------------------------
go: $(GO_BIN)

$(GO_BIN): | $(BIN_DIR)
	@echo "===> Compilazione versione Go..."
	@cd go && $(GO) build -o ../$@ main.go
	@echo "OK: Generato $@"

# ------------------------------------------------------------------------------
# 4. Variante C
# ------------------------------------------------------------------------------
c: $(CC_BIN)

C_SRCS := $(wildcard c/*.c)

$(CC_BIN): $(C_SRCS) | $(BIN_DIR)
	@echo "===> Compilazione versione C..."
	$(CC) $(CFLAGS) $(C_SRCS) -o $@ $(LDFLAGS)
	@echo "OK: Generato $@"

# Create la cartella bin/ se non esiste
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# ------------------------------------------------------------------------------
# Pulizia dei file generati
# ------------------------------------------------------------------------------
clean:
	@echo "===> Pulizia di tutti i target di build..."
	@rm -rf $(BIN_DIR)
	@-cd ada && $(ALR) clean 2>/dev/null || true
	@-cd rust && $(CARGO) clean 2>/dev/null || true
	@-rm -f go/rrdespike 2>/dev/null || true
	@-rm -f c/*.o 2>/dev/null || true
	@echo "Pulizia completata."

# Guida rapida agli obiettivi
help:
	@echo "Uso del Makefile:"
	@echo "  make          : Compila tutte le 4 varianti (Ada, Rust, Go, C)"
	@echo "  make ada      : Compila solo la versione Ada  -> bin/rrdespike-ada"
	@echo "  make rust     : Compila solo la versione Rust -> bin/rrdespike-rs"
	@echo "  make go       : Compila solo la versione Go   -> bin/rrdespike-go"
	@echo "  make c        : Compila solo la versione C    -> bin/rrdespike-cc"
	@echo "  make clean    : Rimuove i binari ed esegue la pulizia nelle sottocartelle"

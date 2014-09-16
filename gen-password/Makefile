INSTALL_DIR=$(HOME)/.local/bin/
BUILD_DIR=./build/
SRC_DIR=./src/

$(BUILD_DIR)gen-password: $(SRC_DIR)gen-password.rs
	test -d $(BUILD_DIR) || mkdir $(BUILD_DIR)
	rustc $(SRC_DIR)gen-password.rs -o $(BUILD_DIR)gen-password

all: $(BUILD_DIR)gen-password

clean:
	rm -f $(BUILD_DIR)gen-password
	rm -f $(BUILD_DIR)test-gen-password

install: $(BUILD_DIR)gen-password
	cp $(BUILD_DIR)gen-password $(INSTALL_DIR)

test: $(SRC_DIR)gen-password.rs
	test -d $(BUILD_DIR) || mkdir $(BUILD_DIR)
	rustc $(SRC_DIR)gen-password.rs --test -o $(BUILD_DIR)test-gen-password 2> /dev/null
	$(BUILD_DIR)test-gen-password
	rm -f $(BUILD_DIR)test-gen-password

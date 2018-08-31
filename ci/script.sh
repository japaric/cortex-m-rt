set -euxo pipefail

main() {
    cargo check --target $TARGET

    cargo check --target $TARGET --features device

    ( cd macros && cargo check && cargo test )

    local examples=(
        alignment
        minimal
        main
        override-exception
        pre_init
        state
    )
    local fail_examples=(
        data_overflow
    )
    if [ $TRAVIS_RUST_VERSION = nightly ]; then
        # linking with GNU LD
        for ex in "${examples[@]}"; do
            cargo rustc --target $TARGET --example $ex -- \
                  -C linker=arm-none-eabi-ld \
                  -C link-arg=-Tlink.x

            cargo rustc --target $TARGET --example $ex --release -- \
                  -C linker=arm-none-eabi-ld \
                  -C link-arg=-Tlink.x
        done
        for ex in "${fail_examples[@]}"; do
            ! cargo rustc --target $TARGET --example $ex -- \
                  -C linker=arm-none-eabi-ld \
                  -C link-arg=-Tlink.x

            ! cargo rustc --target $TARGET --example $ex --release -- \
                  -C linker=arm-none-eabi-ld \
                  -C link-arg=-Tlink.x
        done

        cargo rustc --target $TARGET --example device --features device -- \
              -C linker=arm-none-eabi-ld \
              -C link-arg=-Tlink.x

        cargo rustc --target $TARGET --example device --features device --release -- \
              -C linker=arm-none-eabi-ld \
              -C link-arg=-Tlink.x

        # linking with rustc's LLD
        for ex in "${examples[@]}"; do
            cargo rustc --target $TARGET --example $ex -- \
                  -C linker=rust-lld \
                  -C link-arg=-Tlink.x

            cargo rustc --target $TARGET --example $ex --release -- \
                  -C linker=rust-lld \
                  -C link-arg=-Tlink.x
        done
        for ex in "${fail_examples[@]}"; do
            ! cargo rustc --target $TARGET --example $ex -- \
                  -C linker=rust-lld \
                  -C link-arg=-Tlink.x

            ! cargo rustc --target $TARGET --example $ex --release -- \
                  -C linker=rust-lld \
                  -C link-arg=-Tlink.x
        done

        cargo rustc --target $TARGET --example device --features device -- \
              -C linker=rust-lld \
              -C link-arg=-Tlink.x

        cargo rustc --target $TARGET --example device --features device --release -- \
              -C linker=rust-lld \
              -C link-arg=-Tlink.x
    fi

    if [ $TARGET = x86_64-unknown-linux-gnu ]; then
        ./check-blobs.sh
    fi
}

main

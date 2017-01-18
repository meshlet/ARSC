    // Initialize starting x-coordinate to 0
    LDA ZERO
    STA START_X_COORD

    LDA INITIAL_PX_WORD_ADDR
    STA LEFTMOST_PX_WORD_ADDR
    LDA ZERO
    STA LEFTMOST_PX_WORD_OFFSET

    // Set initial velocity to 1 (moves to the right, one pixel at the time)
    LDA THREE
    STA SQUARE_VELOCITY

    // Indicate that square must be erased before it is moved
    STA SHOULD_ERASE

MAIN_LOOP:
    // Index registers 2 and 3 are used as the loop variables for the draw double loop
    LDA SQUARE_SIZE
    ADD ONE
    TCA
    STA TMP
    LDX TMP,2

    LDA LEFTMOST_PX_WORD_ADDR
    STA LINE_START_PX_WORD_ADDR
    LDA LEFTMOST_PX_WORD_OFFSET
    STA LINE_START_PX_WORD_OFFSET

    // Set pixel color to RED or WHITE depending on SHOULD_ERASE
    LDA SHOULD_ERASE
    BIP SET_RED_COLOR
    LDA SEVEN // WHITE
    STA PX_COLOR
    BRU OUTER_DRAW_LOOP

SET_RED_COLOR:
    LDA FOUR // RED
    STA PX_COLOR

OUTER_DRAW_LOOP:
    TIX OUTER_DRAW_LOOP_END,2
    LDA LINE_START_PX_WORD_ADDR
    STA PX_WORD_ADDR
    LDA LINE_START_PX_WORD_OFFSET
    STA PX_WORD_OFFSET
    LDA SQUARE_SIZE
    ADD ONE
    TCA
    STA TMP
    LDX TMP,3

INNER_DRAW_LOOP:
    TIX INNER_DRAW_LOOP_END,3

    // Read the pixel from the video memory
    RWD {0} PX_WORD_ADDR
    STA PX_WORD

    // Calculate the pixel mask and number of bits that 3-bit color must be left-shifted to
    // obtain the 16-bit pixel word in which 3-bit color corresponds to the current pixel
    LDA PX_WORD_OFFSET
    BIP IF1
    // Pixel offset is 0
    LDA ZERO
    STA SHIFT_COUNT
    LDA MASK0
    STA PX_MASK
    BRU CALC_MASK_END

IF1:
    ADD MINONE
    BIP IF2
    // Pixel offset is 1
    LDA THREE
    STA SHIFT_COUNT
    LDA MASK1
    STA PX_MASK
    BRU CALC_MASK_END

IF2:
    ADD MINONE
    BIP IF3
    // Pixel offset is 2
    LDA SIX
    STA SHIFT_COUNT
    LDA MASK2
    STA PX_MASK
    BRU CALC_MASK_END

IF3:
    ADD MINONE
    BIP IF4
    // Pixel offset is 3
    LDA NINE
    STA SHIFT_COUNT
    LDA MASK3
    STA PX_MASK
    BRU CALC_MASK_END

IF4:
    // Pixel offset is 4
    LDA TWELVE
    STA SHIFT_COUNT
    LDA MASK4
    STA PX_MASK

CALC_MASK_END:

    // Left-shift 3-bit color into 16-bit word
    LDA SHIFT_COUNT
    ADD ONE
    TCA
    STA TMP
    LDX TMP,1
    LDA PX_COLOR

BUILD_PX_WORD:
    TIX BUILD_PX_WORD_END,1
    SHL
    BRU BUILD_PX_WORD

BUILD_PX_WORD_END:

    // New pixel = (old pixel & mask) | new pixel color word
    STA TMP
    LDA PX_WORD
    AND PX_MASK
    OR TMP

    // Write pixel
    WWD {0} PX_WORD_ADDR

    // Calculate the pixel address and offset for the next pixel
    LDA PX_WORD_OFFSET
    ADD ONE
    STA PX_WORD_OFFSET
    TCA
    ADD FIVE
    BIP INNER_DRAW_LOOP
    LDA ZERO
    STA PX_WORD_OFFSET
    LDA PX_WORD_ADDR
    ADD ONE
    STA PX_WORD_ADDR
    BRU INNER_DRAW_LOOP

INNER_DRAW_LOOP_END:

    LDA LINE_START_PX_WORD_ADDR
    ADD ONE_HND_TWENTY_EIGTH
    STA LINE_START_PX_WORD_ADDR
    BRU OUTER_DRAW_LOOP

OUTER_DRAW_LOOP_END:

    // If this was erase-square step, skip the stall and move to velocity update
    LDA SHOULD_ERASE
    BIN VELOCITY_UPDATE_START

    // Stall the animation. Taking only INNER_STALL_LOOP under consideration, TIX
    // instruction takes around 6 cycles and SHL and BRU around 5, in total 16 cycles.
    // Each cycle is 20ns, so one iteration is 320ns. To get around 50ms worth of time
    // one needs: 50ms/320ns ~- 200000 iterations
    LDX MINFIVE_HND_AND_ONE,1

OUTER_STALL_LOOP:
    TIX OUTER_STALL_LOOP_END,1
    LDX MINFOUR_HND_AND_ONE,2

INNER_STALL_LOOP:
    TIX INNER_STALL_LOOP_END,2
    SHL
    BRU INNER_STALL_LOOP

INNER_STALL_LOOP_END:

    BRU OUTER_STALL_LOOP

OUTER_STALL_LOOP_END:

    // Square must be erased from its current position before it is moved
    LDA MINONE
    STA SHOULD_ERASE
    BRU MAIN_LOOP

VELOCITY_UPDATE_START:
    // Check if left or right wall has been reached and modify velocity accordingly
    LDA SQUARE_VELOCITY
    BIP VELOCITY_POSITIVE
    // Velocity < 0 (square moves to the left) - check if left wall has been reached
    ADD START_X_COORD
    BIN CHANGE_DIRECTION
    BRU VELOCITY_UPDATE_DONE

VELOCITY_POSITIVE:
    // Velocity > 0 (square moves to the right) - check if right wall has been reached
    ADD START_X_COORD
    ADD SQUARE_SIZE
    TCA
    ADD SCREEN_WIDTH
    BIP VELOCITY_UPDATE_DONE

CHANGE_DIRECTION:
    LDA SQUARE_VELOCITY
    TCA
    STA SQUARE_VELOCITY

VELOCITY_UPDATE_DONE:

    // Move the square
    LDA START_X_COORD
    ADD SQUARE_VELOCITY
    STA START_X_COORD

    // Calculate the next left-most pixel address and offset for the square
    LDA SQUARE_VELOCITY
    BIP CALC_PX_ADDR_VELOCITY_POSITIVE
    // Velocity < 0
    LDA LEFTMOST_PX_WORD_OFFSET
    ADD SQUARE_VELOCITY
    BIN NEW_OFFSET_NEGATIVE
    STA LEFTMOST_PX_WORD_OFFSET
    BRU ADDR_OFFSET_UPDATE_DONE

NEW_OFFSET_NEGATIVE:
    ADD FIVE
    STA LEFTMOST_PX_WORD_OFFSET
    LDA LEFTMOST_PX_WORD_ADDR
    ADD MINONE
    STA LEFTMOST_PX_WORD_ADDR
    BRU ADDR_OFFSET_UPDATE_DONE

CALC_PX_ADDR_VELOCITY_POSITIVE:
    // Velocity > 0
    LDA LEFTMOST_PX_WORD_OFFSET
    ADD SQUARE_VELOCITY
    STA LEFTMOST_PX_WORD_OFFSET
    TCA
    ADD FIVE
    BIP ADDR_OFFSET_UPDATE_DONE
    TCA
    STA LEFTMOST_PX_WORD_OFFSET
    LDA LEFTMOST_PX_WORD_ADDR
    ADD ONE
    STA LEFTMOST_PX_WORD_ADDR

ADDR_OFFSET_UPDATE_DONE:

    // Square should be erased as part of the next iteration
    LDA ONE
    STA SHOULD_ERASE
    BRU MAIN_LOOP

MAIN_LOOP_END:
    HLT

LEFTMOST_PX_WORD_ADDR BSS 1
LEFTMOST_PX_WORD_OFFSET BSS 1
LINE_START_PX_WORD_ADDR BSS 1
LINE_START_PX_WORD_OFFSET BSS 1
PX_WORD_ADDR BSS 1
PX_WORD_OFFSET BSS 1
START_X_COORD BSS 1
START_PX_WORD_ADDR BSS 1
START_PX_WORD_OFFSET BSS 1
SHIFT_COUNT BSS 1
INITIAL_PX_WORD_ADDR BSC 24320
SQUARE_VELOCITY BSS 1
PX_WORD BSS 1
PX_MASK BSS 1
TMP BSS 1
SHOULD_ERASE BSS 1
SCREEN_WIDTH BSC 640
SQUARE_SIZE BSC 50 // 50 pixels in both dimensions
ZERO BSC 0
ONE BSC 1
THREE BSC 3
FOUR BSC 4
FIVE BSC 5
SIX BSC 6
SEVEN BSC 7
NINE BSC 9
TWELVE BSC 12
MASK0 BSC 32760
MASK1 BSC 32711
MASK2 BSC 32319
MASK3 BSC 29183
MASK4 BSC 4095
MINONE BSC -1
MINFOUR_HND_AND_ONE BSC -401
MINFIVE_HND_AND_ONE BSC -501
ONE_HND_TWENTY_EIGTH BSC 128
PX_COLOR BSS 1 // 3-bit color

END
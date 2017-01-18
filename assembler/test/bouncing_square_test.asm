    // Initialize starting x-coordinate to 0
    LDA ZERO
    STA START_X_COORD

    // Set initial velocity to 1 (moves to the right, one pixel at the time)
    LDA ONE
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

    // Set y-coordinate to its initial value
    LDA Y_COORD
    STA PX_Y_COORD

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
    LDA START_X_COORD
    STA PX_X_COORD
    LDA SQUARE_SIZE
    ADD ONE
    TCA
    STA TMP
    LDX TMP,3

INNER_DRAW_LOOP:
    TIX INNER_DRAW_LOOP_END,3

    // For given pixel coords. (x,y), the 1-D coordinate is calculated as 640*y + x (assuming
    // that screen is 640 pixels wide). As each 16-bit video memory word contains 5 pixels, the
    // memory address is obtained as (640*y + x) / 5. The remainder is the offset of this pixel
    // within the 16-bit word. This expression can be simplified in the following way:
    // (640*y + x) / 5 = 128*y + x/5 = (y << 7) + x/5. The sum of (y << 7) and quotient of x/5
    // represents the memory address of the pixel and remainder of x/5 is the pixel offset.
    //
    // x/5 operation
    // Performs long division dvnd/dvsr, where dvnd,dvsr > 0
    LDA FIVE
    TCA
    ADD PX_X_COORD
    BIN DVND_LT_DVSR
    BIP DVND_GT_DVSR
    // DVND == DVSR
    LDA ONE
    STA PX_WORD_ADDR
    LDA ZERO
    STA PX_WORD_OFFSET
    BRU DIV_END

DVND_LT_DVSR:
    // DVND < DVSR
    LDA ZERO
    STA PX_WORD_ADDR
    LDA PX_X_COORD
    STA PX_WORD_OFFSET
    BRU DIV_END

DVND_GT_DVSR:
    // DVND > DVSR
    LDA FIVE
    STA TMP_Y
    LDX ZERO,1
    LDA ZERO
    STA BUFFER

PREP_BUFF:
    LDA TMP_Y
    BIP PREP_BUFF_CHCK_COND
    BRU PREP_BUFF_END

PREP_BUFF_CHCK_COND:
    // Check if TMP_Y <= DVND
    TCA
    ADD PX_X_COORD
    BIN PREP_BUFF_END
    // Index += 1
    STX IDX,1
    LDA IDX
    ADD ONE
    STA IDX
    LDX IDX,1
    // BUFFER[INDEX] = TMP_Y
    LDA TMP_Y
    STA BUFFER,1
    // TMP_Y = 2*TMP_Y
    SHL
    STA TMP_Y
    BRU PREP_BUFF

PREP_BUFF_END:

    // TMP_Y = BUFFER[INDEX]
    LDA BUFFER,1
    STA TMP_Y
    // TMP_X = DVND
    LDA PX_X_COORD
    STA TMP_X
    // Index -= 1
    STX IDX,1
    LDA IDX
    ADD MINONE
    STA IDX
    LDX IDX,1
    // Quotient = 0
    LDA ZERO
    STA PX_WORD_ADDR

DIV_LOOP:
    // Index >= 0
    STX IDX,1
    LDA IDX
    BIN SET_REMAINDER
    LDA TMP_Y
    TCA
    ADD TMP_X
    BIN TMPX_LT_TMPY
    // Quotient = 2*Quotient + 1
    LDA PX_WORD_ADDR
    SHL
    ADD ONE
    STA PX_WORD_ADDR
    // TMP_X -= TMP_Y
    LDA TMP_Y
    TCA
    ADD TMP_X
    STA TMP_X
    BRU DIV_LOOP_NEXT

TMPX_LT_TMPY:
    // Quotient = 2*Quotient
    LDA PX_WORD_ADDR
    SHL
    STA PX_WORD_ADDR

DIV_LOOP_NEXT:
    // TMP_Y -= BUFFER[INDEX]
    LDA BUFFER,1
    TCA
    ADD TMP_Y
    STA TMP_Y
    // Index -= 1
    STX IDX,1
    LDA IDX
    ADD MINONE
    STA IDX
    LDX IDX,1
    BRU DIV_LOOP

SET_REMAINDER:
    LDA TMP_X
    STA PX_WORD_OFFSET

DIV_END:

    // y << 7
    LDA PX_Y_COORD
    LDX MINEIGHT,1

SHIFT_LOOP:
    TIX SHIFT_LOOP_END,1
    SHL
    BRU SHIFT_LOOP

SHIFT_LOOP_END:
    // Add y<<7 to quotient of x/5 to get the full pixel memory address
    ADD PX_WORD_ADDR
    STA PX_WORD_ADDR

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

    // Increment pixel x-coordinate and go to next iteration of INNER DRAW LOOP
    LDA PX_X_COORD
    ADD ONE
    STA PX_X_COORD
    BRU INNER_DRAW_LOOP

INNER_DRAW_LOOP_END:

    // Increment pixel y-coordinate and go to next iteration of OUTER DRAW LOOP
    LDA PX_Y_COORD
    ADD ONE
    STA PX_Y_COORD
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

    // Move the square and prepare for the next iteration
    LDA START_X_COORD
    ADD SQUARE_VELOCITY
    STA START_X_COORD
    LDA ONE
    STA SHOULD_ERASE
    BRU MAIN_LOOP

MAIN_LOOP_END:
    HLT

PX_X_COORD BSS 1
PX_Y_COORD BSS 1
START_X_COORD BSS 1
SQUARE_VELOCITY BSS 1
PX_WORD BSS 1
PX_MASK BSS 1
BUFFER BSS 16
TMP_X BSS 1
TMP_Y BSS 1
IDX BSS 1
TMP BSS 1
SHIFT_COUNT BSS 1
SHOULD_ERASE BSS 1
Y_COORD BSC 190
SCREEN_WIDTH BSC 640
SQUARE_SIZE BSC 25 // 50 pixels in both dimensions
MINEIGHT BSC -8
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
PX_COLOR BSS 1 // 3-bit color
PX_WORD_ADDR BSS 1
PX_WORD_OFFSET BSS 1

END
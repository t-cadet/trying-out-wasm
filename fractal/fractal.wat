(module

  (import "mem" "pages" (memory 24))

  (global $PALETTE_OFFSET (import "mem" "paletteOffset") i32)

  (global $BAILOUT f32 (f32.const 4.0))
  (global $BLACK i32 (i32.const 0xFF000000))

;; PALETTE
(func $8_bit_clamp
    (param $n i32)
    (param $threshold i32)
    (result i32)

  (local $temp i32)

  (local.set $temp
    (i32.and (i32.add (local.get $n) (local.get $threshold))
             (i32.const 1023)
    )
  )

  ;; How many bits does $temp use?
  (if (result i32)
    ;; 9 or more bits?
    (i32.ge_u (local.get $temp) (i32.const 256))
    (then
      ;; If bit 10 is switched off invert value, else return zero
      (if (result i32 )
        (i32.lt_u (local.get $temp) (i32.const 512))
        (then (i32.sub (i32.const 510) (local.get $temp)))
        (else (i32.const 0))
      )
    )
    (else (local.get $temp))
  )
)
(func $red   (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const   0)))
(func $green (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 128)))
(func $blue  (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 356)))
(func $colour
      (param $iter i32)
      (result i32)

  (local $iter4 i32)
  (local.set $iter4 (i32.shl (local.get $iter) (i32.const 2)))

  ;; Little-endian processors require the colour component values in ABGR order, not RGBA
  (i32.or
    (i32.or
      (i32.const 0xFF000000)   ;; Fully opaque
      (i32.shl (call $blue (local.get $iter4)) (i32.const 16))
    )
    (i32.or
      (i32.shl (call $green (local.get $iter4)) (i32.const 8))
      (call $red (local.get $iter4))
    )
  )
)
(func (export "gen_palette")
      (param $max_iters i32)

  (local $idx i32)

  (loop $next
    (if (i32.gt_u (local.get $max_iters) (local.get $idx))
      (then
        (i32.store
           (i32.add (global.get $PALETTE_OFFSET) (i32.shl (local.get $idx) (i32.const 2)))
           (call $colour (local.get $idx))
        )

        (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
        (br $next)
      )
    )
  )
)

;; MANDELBROT:
  (func $dup (param i32) (result i32 i32)
    local.get 0
    local.get 0
  )

  (func $center (param $a i32) (param $size i32) (result i32)
    ;; a
    local.get 0
    local.get 1
    i32.const 2
    i32.div_u
    i32.sub
  )

  ;; check for early bailout
  ;; if (x,y) in cardioid or bulb
  (func $shouldBailoutEarly (param $x f32) (param $y f32) (result i32)
    (local $ySquared f32)
    (local $xMinusOneFourth f32)
    (local $xPlusOne f32)
    (local $q f32)

    local.get $y
    local.get $y
    f32.mul
    local.tee $ySquared

    local.get $x
    f32.const 0.25
    f32.sub
    local.tee $xMinusOneFourth
    local.get $xMinusOneFourth
    f32.mul

    f32.add

    local.tee $q
    local.get $xMinusOneFourth
    f32.add
    local.get $q
    f32.mul

    f32.const 0.25
    local.get $ySquared
    f32.mul

    f32.lt

    local.get $x
    f32.const 1
    f32.add
    local.tee $xPlusOne
    local.get $xPlusOne
    f32.mul
    local.get $ySquared
    f32.add
    f32.const 0.0625
    f32.lt

    i32.or
  )
  ;; f_c(z) = z*z + c
  (func $mandelbrotPixelShader (param $_x f32) (param $_y f32) (result i32)
    (local $i i32)

    (local $x f32)
    (local $y f32)

    (local $zx f32)
    (local $zy f32)
    (local $zxSquared f32)
    (local $zySquared f32)

    local.get $_x
    f32.const 2.74
    f32.mul
    f32.const 2.1
    f32.sub
    local.tee $x

    local.get $_y
    f32.const 2.5
    f32.mul
    f32.const 1.25
    f32.sub
    local.tee $y

    call $shouldBailoutEarly
    if
      i32.const 1000
      local.set $i
    else
      ;; escape time loop
      loop $loop
        local.get $i
        i32.const 1000
        i32.lt_u

        local.get $zx
        local.get $zx
        f32.mul
        local.tee $zxSquared
        local.get $zy
        local.get $zy
        f32.mul
        local.tee $zySquared
        f32.add
        global.get $BAILOUT
        f32.lt

        i32.and
        if
          ;; y := 2*x*y + y0
          local.get $zx
          local.get $zx
          f32.add
          local.get $zy
          f32.mul
          local.get $y
          f32.add
          local.set $zy

          ;; xtemp := x^2 - y^2 + x0
          local.get $zxSquared
          local.get $zySquared
          f32.sub
          local.get $x
          f32.add
          local.set $zx

          local.get $i
          i32.const 1
          i32.add
          local.set $i
          br $loop
        end
      end
    end
    global.get $PALETTE_OFFSET
    local.get $i
    i32.const 2
    i32.shl
    i32.add
    i32.load
  )

  (func (export "mandelbrot") (param $w i32) (param $h i32)
    (local $w_i i32)
    (local $h_i i32)

    (local $w_f f32)
    (local $h_f f32)

    local.get $w
    f32.convert_i32_u
    local.set $w_f

    local.get $h
    f32.convert_i32_u
    local.set $h_f

    loop $loop_h
      ;; i < h
      local.get $h_i
      local.get $h
      i32.lt_u
      if
        loop $loop_w
          ;; i < w
          local.get $w_i
          local.get $w
          i32.lt_u
          if
            ;; dest address
            local.get $h_i
            local.get $w
            i32.mul
            local.get $w_i
            i32.add

            i32.const 2
            i32.shl

            ;; pixel color
            local.get $w_i
            f32.convert_i32_u
            local.get $w_f
            f32.div

            local.get $h_i
            f32.convert_i32_u
            local.get $h_f
            f32.div
            call $mandelbrotPixelShader

            i32.store

            ;; w_i += 1
            local.get $w_i
            i32.const 1
            i32.add
            local.set $w_i
            br $loop_w
          end
        end
        i32.const 0
        local.set $w_i

        ;; h_i += 1
        local.get $h_i
        i32.const 1
        i32.add
        local.set $h_i
        br $loop_h
      end
    end
  )
)

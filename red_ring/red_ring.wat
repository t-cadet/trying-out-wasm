(module
  (import "math" "sin" (func $sin (param f64) (result f64)))
  (import "math" "cos" (func $cos (param f64) (result f64)))
  (import "math" "tan" (func $tan (param f64) (result f64)))
  (import "math" "log" (func $log (param f64) (result f64)))

  (import "mem" "pages" (memory 1))

  (global $offset (import "mem" "offset") i32)
  
  (func (export "loop") (result i32)
    (local $i i32)
    loop $loop
      local.get $i
      i32.const 1
      i32.add
      local.set $i

      local.get $i
      i32.const 10
      i32.lt_s
      br_if $loop
    end
    local.get $i
  )
  ;; comment
  (func (export "answer") (result i32)
    i32.const 42
  )

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

  (func $pixelShader (param $x i32) (param $y i32) (param $size i32) (result i32)
    (local $rSquared i32)
    ;; r²
    local.get $x
    local.get $size
    call $center
    call $dup
    i32.mul

    local.get $y
    local.get $size
    call $center
    call $dup
    i32.mul

    i32.add

    local.set $rSquared

    ;; x/10
    local.get $rSquared
    local.get $size
    i32.const 10
    i32.mul
    i32.lt_u

    local.get $rSquared
    local.get $size
    i32.const 5
    i32.mul
    i32.gt_u

    i32.and

    if (result i32)
      i32.const 0xFF0000FF
    else
      i32.const 0xFF242424
    end
  )

  (func (export "shader") (param $size i32) (result i32)
    (local $i i32)
    loop $loop
      ;; i < w * h
      local.get $i
      local.get $size
      local.get $size
      ;; call $dup
      i32.mul
      i32.lt_u
      if
        ;; dest address
        local.get $i
        i32.const 2
        i32.shl

        ;; pixel color
        local.get $i
        local.get $size
        i32.rem_u
        local.get $i
        local.get $size
        i32.div_u
        local.get $size
        call $pixelShader

        i32.store

        ;; i += 1
        local.get $i
        i32.const 1
        i32.add
        local.set $i

        br $loop
      end
    end

    ;; i * 4
    local.get $i
    i32.const 2
    i32.shl
  )
)

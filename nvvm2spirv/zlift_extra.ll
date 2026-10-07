; Hand-written members of the Intel PTX device library.
;
; These three cannot be spelled in OpenCL C. `div_f32_part1` returns a literal
; struct whose *name* has to match what ZLUDA's front end declares, and
; `vote.sync.ballot` takes an `i1` predicate. Writing them here keeps the
; signatures exact instead of hoping clang picks the same lowering.
;
; `div.rn.f32` is split in two for AMD because that hardware needs an explicit
; Newton-Raphson dance around `div_scale`. Xe has a real divide, and the second
; half is handed the original operands, so all the work fits there and the
; first half only has to produce a struct nobody reads.

target triple = "spir64-unknown-unknown"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"

%struct.f32.f32.f32.i8 = type { float, float, float, i8 }

declare spir_func i32 @__zlift_vote_ballot(i32)

define spir_func %struct.f32.f32.f32.i8
    @__zluda_ptx_impl_div_f32_part1(float %x, float %y) #90 {
  ret %struct.f32.f32.f32.i8 zeroinitializer
}

define spir_func float
    @__zluda_ptx_impl_div_f32_part2(float %x, float %y, float %a, float %b,
                                    float %c, i8 %flag) #90 {
  %r = fdiv float %x, %y
  ret float %r
}

define spir_func i32
    @__zluda_ptx_impl_vote_sync_ballot_b32(i1 %pred, i32 %membermask) #90 {
  %p = zext i1 %pred to i32
  %r = call spir_func i32 @__zlift_vote_ballot(i32 %p)
  ret i32 %r
}

attributes #90 = { alwaysinline convergent nounwind }

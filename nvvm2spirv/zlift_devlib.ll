; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

%struct.f32.f32.f32.i8 = type { float, float, float, i8 }

@ZLIFT_DPAS_K = internal unnamed_addr addrspace(2) constant [16 x i8] c"\00\01\08\09\02\03\0A\0B\04\05\0C\0D\06\07\0E\0F", align 1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zlift_match_any_b32(i32 noundef %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %10

3:                                                ; preds = %3, %1
  %4 = phi i32 [ 0, %1 ], [ %10, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %11, %3 ]
  %6 = tail call spir_func i32 @_Z19sub_group_broadcastjj(i32 noundef %0, i32 noundef %5) #10
  %7 = icmp eq i32 %6, %0
  %8 = shl nuw i32 1, %5
  %9 = select i1 %7, i32 %8, i32 0
  %10 = or i32 %9, %4
  %11 = add nuw nsw i32 %5, 1
  %12 = icmp samesign ult i32 %5, 31
  br i1 %12, label %3, label %2
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z19sub_group_broadcastjj(i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zlift_activemask() local_unnamed_addr #0 {
  %1 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %2 = and i32 %1, 31
  %3 = shl nuw i32 1, %2
  %4 = tail call spir_func i32 @_Z20sub_group_reduce_addi(i32 noundef %3) #10
  ret i32 %4
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z22get_sub_group_local_idv() local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z20sub_group_reduce_addi(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func range(i32 0, 2) i32 @__zlift_elect_sync() local_unnamed_addr #0 {
  %1 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = and i32 %2, 31
  %4 = shl nuw i32 1, %3
  %5 = tail call spir_func i32 @_Z20sub_group_reduce_addi(i32 noundef %4) #10
  %6 = tail call spir_func i32 @_Z3ctzj(i32 noundef %5) #11
  %7 = icmp eq i32 %1, %6
  %8 = zext i1 %7 to i32
  ret i32 %8
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func i32 @_Z3ctzj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zlift_prmt_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = zext i32 %1 to i64
  %5 = shl nuw i64 %4, 32
  %6 = zext i32 %0 to i64
  %7 = or disjoint i64 %5, %6
  %8 = shl i32 %2, 3
  %9 = and i32 %8, 56
  %10 = zext nneg i32 %9 to i64
  %11 = lshr i64 %7, %10
  %12 = trunc i64 %11 to i32
  %13 = and i32 %12, 255
  %14 = lshr i32 %2, 1
  %15 = and i32 %14, 56
  %16 = zext nneg i32 %15 to i64
  %17 = lshr i64 %7, %16
  %18 = trunc i64 %17 to i32
  %19 = and i32 %18, 255
  %20 = insertelement <4 x i32> poison, i32 %18, i64 0
  %21 = insertelement <4 x i32> %20, i32 %2, i64 1
  %22 = insertelement <4 x i32> %21, i32 %12, i64 2
  %23 = shufflevector <4 x i32> %22, <4 x i32> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 1>
  %24 = and <4 x i32> %23, <i32 128, i32 128, i32 128, i32 8>
  %25 = icmp eq <4 x i32> %24, zeroinitializer
  %26 = extractelement <4 x i1> %25, i64 2
  %27 = select i1 %26, i32 0, i32 255
  %28 = extractelement <4 x i1> %25, i64 3
  %29 = select i1 %28, i32 %13, i32 %27
  %30 = extractelement <4 x i1> %25, i64 0
  %31 = select i1 %30, i32 0, i32 255
  %32 = extractelement <4 x i1> %25, i64 1
  %33 = select i1 %32, i32 %19, i32 %31
  %34 = shl nuw nsw i32 %33, 8
  %35 = or disjoint i32 %34, %29
  %36 = insertelement <2 x i32> poison, i32 %2, i64 0
  %37 = shufflevector <2 x i32> %36, <2 x i32> poison, <2 x i32> zeroinitializer
  %38 = lshr <2 x i32> %37, <i32 9, i32 5>
  %39 = and <2 x i32> %37, <i32 32768, i32 2048>
  %40 = and <2 x i32> %38, splat (i32 56)
  %41 = zext nneg <2 x i32> %40 to <2 x i64>
  %42 = insertelement <2 x i64> poison, i64 %7, i64 0
  %43 = shufflevector <2 x i64> %42, <2 x i64> poison, <2 x i32> zeroinitializer
  %44 = lshr <2 x i64> %43, %41
  %45 = trunc <2 x i64> %44 to <2 x i32>
  %46 = and <2 x i32> %45, splat (i32 255)
  %47 = icmp eq <2 x i32> %39, zeroinitializer
  %48 = and <2 x i64> %44, splat (i64 128)
  %49 = icmp eq <2 x i64> %48, zeroinitializer
  %50 = select <2 x i1> %49, <2 x i32> zeroinitializer, <2 x i32> splat (i32 255)
  %51 = select <2 x i1> %47, <2 x i32> %46, <2 x i32> %50
  %52 = shl nuw <2 x i32> %51, <i32 24, i32 16>
  %53 = extractelement <2 x i32> %52, i64 1
  %54 = or disjoint i32 %53, %35
  %55 = extractelement <2 x i32> %52, i64 0
  %56 = or disjoint i32 %55, %54
  ret i32 %56
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func i64 @__zlift_bfi_b64(i64 noundef %0, i64 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #3 {
  %5 = icmp ugt i32 %2, 63
  %6 = icmp eq i32 %3, 0
  %7 = or i1 %5, %6
  br i1 %7, label %30, label %8

8:                                                ; preds = %4
  %9 = add i32 %3, %2
  %10 = icmp ugt i32 %9, 64
  %11 = sub nuw nsw i32 64, %2
  %12 = select i1 %10, i32 %11, i32 %3
  %13 = icmp ugt i32 %12, 63
  br i1 %13, label %14, label %16

14:                                               ; preds = %8
  %15 = zext nneg i32 %2 to i64
  br label %22

16:                                               ; preds = %8
  %17 = zext nneg i32 %12 to i64
  %18 = shl nsw i64 -1, %17
  %19 = xor i64 %18, -1
  %20 = zext nneg i32 %2 to i64
  %21 = shl i64 %19, %20
  br label %22

22:                                               ; preds = %16, %14
  %23 = phi i64 [ %15, %14 ], [ %20, %16 ]
  %24 = phi i64 [ -1, %14 ], [ %21, %16 ]
  %25 = xor i64 %24, -1
  %26 = and i64 %1, %25
  %27 = shl i64 %0, %23
  %28 = and i64 %24, %27
  %29 = or i64 %26, %28
  br label %30

30:                                               ; preds = %22, %4
  %31 = phi i64 [ %29, %22 ], [ %1, %4 ]
  ret i64 %31
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zlift_bfe_u32(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = icmp eq i32 %2, 0
  %5 = icmp ugt i32 %1, 31
  %6 = or i1 %5, %4
  br i1 %6, label %19, label %7

7:                                                ; preds = %3
  %8 = add i32 %2, %1
  %9 = icmp ugt i32 %8, 32
  %10 = sub nuw nsw i32 32, %1
  %11 = select i1 %9, i32 %10, i32 %2
  %12 = lshr i32 %0, %1
  %13 = icmp ugt i32 %11, 31
  %14 = and i32 %11, 31
  %15 = shl nsw i32 -1, %14
  %16 = xor i32 %15, -1
  %17 = select i1 %13, i32 -1, i32 %16
  %18 = and i32 %17, %12
  br label %19

19:                                               ; preds = %7, %3
  %20 = phi i32 [ %18, %7 ], [ 0, %3 ]
  ret i32 %20
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zlift_bfe_s32(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = icmp eq i32 %2, 0
  br i1 %4, label %18, label %5

5:                                                ; preds = %3
  %6 = icmp ugt i32 %1, 31
  br i1 %6, label %7, label %9

7:                                                ; preds = %5
  %8 = ashr i32 %0, 31
  br label %18

9:                                                ; preds = %5
  %10 = add i32 %2, %1
  %11 = icmp ugt i32 %10, 32
  %12 = ashr i32 %0, %1
  %13 = sub i32 0, %2
  %14 = select i1 %11, i32 %1, i32 %13
  %15 = and i32 %14, 31
  %16 = shl i32 %12, %15
  %17 = ashr exact i32 %16, %15
  br label %18

18:                                               ; preds = %9, %7, %3
  %19 = phi i32 [ %8, %7 ], [ %17, %9 ], [ 0, %3 ]
  ret i32 %19
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zlift_bfi_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #3 {
  %5 = icmp ugt i32 %2, 31
  %6 = icmp eq i32 %3, 0
  %7 = or i1 %5, %6
  br i1 %7, label %23, label %8

8:                                                ; preds = %4
  %9 = add i32 %3, %2
  %10 = icmp ugt i32 %9, 32
  %11 = sub nuw nsw i32 32, %2
  %12 = select i1 %10, i32 %11, i32 %3
  %13 = icmp ugt i32 %12, 31
  %14 = shl nsw i32 -1, %12
  %15 = xor i32 %14, -1
  %16 = shl i32 %15, %2
  %17 = select i1 %13, i32 -1, i32 %16
  %18 = xor i32 %17, -1
  %19 = and i32 %1, %18
  %20 = shl i32 %0, %2
  %21 = and i32 %17, %20
  %22 = or i32 %19, %21
  br label %23

23:                                               ; preds = %8, %4
  %24 = phi i32 [ %22, %8 ], [ %1, %4 ]
  ret i32 %24
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zlift_vote_ballot(i32 noundef %0) #0 {
  %2 = icmp eq i32 %0, 0
  br i1 %2, label %7, label %3

3:                                                ; preds = %1
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = and i32 %4, 31
  %6 = shl nuw i32 1, %5
  br label %7

7:                                                ; preds = %3, %1
  %8 = phi i32 [ %6, %3 ], [ 0, %1 ]
  %9 = tail call spir_func i32 @_Z20sub_group_reduce_addi(i32 noundef %8) #10
  ret i32 %9
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func noundef float @__zlift_div_rn_f32(float noundef %0, float noundef %1) local_unnamed_addr #3 {
  %3 = fdiv float %0, %1, !fpmath !4
  ret float %3
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x float> @__zlift_mma_m16n8k8_f32_f16(i32 noundef %0, i32 noundef %1, i32 noundef %2, <4 x float> noundef %3) local_unnamed_addr #0 {
  %5 = extractelement <4 x float> %3, i64 0
  %6 = extractelement <4 x float> %3, i64 1
  %7 = extractelement <4 x float> %3, i64 2
  %8 = extractelement <4 x float> %3, i64 3
  %9 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %10 = and i32 %9, -4
  %11 = shl i32 %9, 3
  %12 = and i32 %11, 24
  %13 = or disjoint i32 %12, 4
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %12) #10
  %15 = trunc i32 %14 to i16
  %16 = bitcast i16 %15 to half
  %17 = fpext half %16 to float
  %18 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %19 = trunc i32 %18 to i16
  %20 = bitcast i16 %19 to half
  %21 = fpext half %20 to float
  %22 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %23 = trunc i32 %22 to i16
  %24 = bitcast i16 %23 to half
  %25 = fpext half %24 to float
  %26 = tail call spir_func float @_Z3fmafff(float noundef %25, float noundef %17, float noundef %5) #11
  %27 = tail call spir_func float @_Z3fmafff(float noundef %25, float noundef %21, float noundef %6) #11
  %28 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %29 = trunc i32 %28 to i16
  %30 = bitcast i16 %29 to half
  %31 = fpext half %30 to float
  %32 = tail call spir_func float @_Z3fmafff(float noundef %31, float noundef %17, float noundef %7) #11
  %33 = tail call spir_func float @_Z3fmafff(float noundef %31, float noundef %21, float noundef %8) #11
  %34 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %12) #10
  %35 = lshr i32 %34, 16
  %36 = trunc nuw i32 %35 to i16
  %37 = bitcast i16 %36 to half
  %38 = fpext half %37 to float
  %39 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %40 = lshr i32 %39, 16
  %41 = trunc nuw i32 %40 to i16
  %42 = bitcast i16 %41 to half
  %43 = fpext half %42 to float
  %44 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %45 = lshr i32 %44, 16
  %46 = trunc nuw i32 %45 to i16
  %47 = bitcast i16 %46 to half
  %48 = fpext half %47 to float
  %49 = tail call spir_func float @_Z3fmafff(float noundef %48, float noundef %38, float noundef %26) #11
  %50 = tail call spir_func float @_Z3fmafff(float noundef %48, float noundef %43, float noundef %27) #11
  %51 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %52 = lshr i32 %51, 16
  %53 = trunc nuw i32 %52 to i16
  %54 = bitcast i16 %53 to half
  %55 = fpext half %54 to float
  %56 = tail call spir_func float @_Z3fmafff(float noundef %55, float noundef %38, float noundef %32) #11
  %57 = tail call spir_func float @_Z3fmafff(float noundef %55, float noundef %43, float noundef %33) #11
  %58 = or disjoint i32 %12, 1
  %59 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %58) #10
  %60 = trunc i32 %59 to i16
  %61 = bitcast i16 %60 to half
  %62 = fpext half %61 to float
  %63 = or disjoint i32 %12, 5
  %64 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %63) #10
  %65 = trunc i32 %64 to i16
  %66 = bitcast i16 %65 to half
  %67 = fpext half %66 to float
  %68 = or disjoint i32 %10, 1
  %69 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %68) #10
  %70 = trunc i32 %69 to i16
  %71 = bitcast i16 %70 to half
  %72 = fpext half %71 to float
  %73 = tail call spir_func float @_Z3fmafff(float noundef %72, float noundef %62, float noundef %49) #11
  %74 = tail call spir_func float @_Z3fmafff(float noundef %72, float noundef %67, float noundef %50) #11
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %68) #10
  %76 = trunc i32 %75 to i16
  %77 = bitcast i16 %76 to half
  %78 = fpext half %77 to float
  %79 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %62, float noundef %56) #11
  %80 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %67, float noundef %57) #11
  %81 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %58) #10
  %82 = lshr i32 %81, 16
  %83 = trunc nuw i32 %82 to i16
  %84 = bitcast i16 %83 to half
  %85 = fpext half %84 to float
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %63) #10
  %87 = lshr i32 %86, 16
  %88 = trunc nuw i32 %87 to i16
  %89 = bitcast i16 %88 to half
  %90 = fpext half %89 to float
  %91 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %68) #10
  %92 = lshr i32 %91, 16
  %93 = trunc nuw i32 %92 to i16
  %94 = bitcast i16 %93 to half
  %95 = fpext half %94 to float
  %96 = tail call spir_func float @_Z3fmafff(float noundef %95, float noundef %85, float noundef %73) #11
  %97 = tail call spir_func float @_Z3fmafff(float noundef %95, float noundef %90, float noundef %74) #11
  %98 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %68) #10
  %99 = lshr i32 %98, 16
  %100 = trunc nuw i32 %99 to i16
  %101 = bitcast i16 %100 to half
  %102 = fpext half %101 to float
  %103 = tail call spir_func float @_Z3fmafff(float noundef %102, float noundef %85, float noundef %79) #11
  %104 = tail call spir_func float @_Z3fmafff(float noundef %102, float noundef %90, float noundef %80) #11
  %105 = or disjoint i32 %12, 2
  %106 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %105) #10
  %107 = trunc i32 %106 to i16
  %108 = bitcast i16 %107 to half
  %109 = fpext half %108 to float
  %110 = or disjoint i32 %12, 6
  %111 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %110) #10
  %112 = trunc i32 %111 to i16
  %113 = bitcast i16 %112 to half
  %114 = fpext half %113 to float
  %115 = or disjoint i32 %10, 2
  %116 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %115) #10
  %117 = trunc i32 %116 to i16
  %118 = bitcast i16 %117 to half
  %119 = fpext half %118 to float
  %120 = tail call spir_func float @_Z3fmafff(float noundef %119, float noundef %109, float noundef %96) #11
  %121 = tail call spir_func float @_Z3fmafff(float noundef %119, float noundef %114, float noundef %97) #11
  %122 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %115) #10
  %123 = trunc i32 %122 to i16
  %124 = bitcast i16 %123 to half
  %125 = fpext half %124 to float
  %126 = tail call spir_func float @_Z3fmafff(float noundef %125, float noundef %109, float noundef %103) #11
  %127 = tail call spir_func float @_Z3fmafff(float noundef %125, float noundef %114, float noundef %104) #11
  %128 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %105) #10
  %129 = lshr i32 %128, 16
  %130 = trunc nuw i32 %129 to i16
  %131 = bitcast i16 %130 to half
  %132 = fpext half %131 to float
  %133 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %110) #10
  %134 = lshr i32 %133, 16
  %135 = trunc nuw i32 %134 to i16
  %136 = bitcast i16 %135 to half
  %137 = fpext half %136 to float
  %138 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %115) #10
  %139 = lshr i32 %138, 16
  %140 = trunc nuw i32 %139 to i16
  %141 = bitcast i16 %140 to half
  %142 = fpext half %141 to float
  %143 = tail call spir_func float @_Z3fmafff(float noundef %142, float noundef %132, float noundef %120) #11
  %144 = tail call spir_func float @_Z3fmafff(float noundef %142, float noundef %137, float noundef %121) #11
  %145 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %115) #10
  %146 = lshr i32 %145, 16
  %147 = trunc nuw i32 %146 to i16
  %148 = bitcast i16 %147 to half
  %149 = fpext half %148 to float
  %150 = tail call spir_func float @_Z3fmafff(float noundef %149, float noundef %132, float noundef %126) #11
  %151 = tail call spir_func float @_Z3fmafff(float noundef %149, float noundef %137, float noundef %127) #11
  %152 = or disjoint i32 %12, 3
  %153 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %152) #10
  %154 = trunc i32 %153 to i16
  %155 = bitcast i16 %154 to half
  %156 = fpext half %155 to float
  %157 = or disjoint i32 %12, 7
  %158 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %157) #10
  %159 = trunc i32 %158 to i16
  %160 = bitcast i16 %159 to half
  %161 = fpext half %160 to float
  %162 = or i32 %9, 3
  %163 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %162) #10
  %164 = trunc i32 %163 to i16
  %165 = bitcast i16 %164 to half
  %166 = fpext half %165 to float
  %167 = tail call spir_func float @_Z3fmafff(float noundef %166, float noundef %156, float noundef %143) #11
  %168 = tail call spir_func float @_Z3fmafff(float noundef %166, float noundef %161, float noundef %144) #11
  %169 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %162) #10
  %170 = trunc i32 %169 to i16
  %171 = bitcast i16 %170 to half
  %172 = fpext half %171 to float
  %173 = tail call spir_func float @_Z3fmafff(float noundef %172, float noundef %156, float noundef %150) #11
  %174 = tail call spir_func float @_Z3fmafff(float noundef %172, float noundef %161, float noundef %151) #11
  %175 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %152) #10
  %176 = lshr i32 %175, 16
  %177 = trunc nuw i32 %176 to i16
  %178 = bitcast i16 %177 to half
  %179 = fpext half %178 to float
  %180 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %157) #10
  %181 = lshr i32 %180, 16
  %182 = trunc nuw i32 %181 to i16
  %183 = bitcast i16 %182 to half
  %184 = fpext half %183 to float
  %185 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %162) #10
  %186 = lshr i32 %185, 16
  %187 = trunc nuw i32 %186 to i16
  %188 = bitcast i16 %187 to half
  %189 = fpext half %188 to float
  %190 = tail call spir_func float @_Z3fmafff(float noundef %189, float noundef %179, float noundef %167) #11
  %191 = tail call spir_func float @_Z3fmafff(float noundef %189, float noundef %184, float noundef %168) #11
  %192 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %162) #10
  %193 = lshr i32 %192, 16
  %194 = trunc nuw i32 %193 to i16
  %195 = bitcast i16 %194 to half
  %196 = fpext half %195 to float
  %197 = tail call spir_func float @_Z3fmafff(float noundef %196, float noundef %179, float noundef %173) #11
  %198 = tail call spir_func float @_Z3fmafff(float noundef %196, float noundef %184, float noundef %174) #11
  %199 = insertelement <4 x float> poison, float %190, i64 0
  %200 = insertelement <4 x float> %199, float %191, i64 1
  %201 = insertelement <4 x float> %200, float %197, i64 2
  %202 = insertelement <4 x float> %201, float %198, i64 3
  ret <4 x float> %202
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @intel_sub_group_shuffle(i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z3fmafff(float noundef, float noundef, float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x float> @__zlift_mma_m16n8k16_f32_f16(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, <4 x float> noundef %6) local_unnamed_addr #0 {
  %8 = extractelement <4 x float> %6, i64 0
  %9 = extractelement <4 x float> %6, i64 1
  %10 = extractelement <4 x float> %6, i64 2
  %11 = extractelement <4 x float> %6, i64 3
  %12 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %13 = and i32 %12, -4
  %14 = shl i32 %12, 3
  %15 = and i32 %14, 24
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %15) #10
  %17 = trunc i32 %16 to i16
  %18 = bitcast i16 %17 to half
  %19 = fpext half %18 to float
  %20 = or disjoint i32 %15, 4
  %21 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %20) #10
  %22 = trunc i32 %21 to i16
  %23 = bitcast i16 %22 to half
  %24 = fpext half %23 to float
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %13) #10
  %26 = trunc i32 %25 to i16
  %27 = bitcast i16 %26 to half
  %28 = fpext half %27 to float
  %29 = tail call spir_func float @_Z3fmafff(float noundef %28, float noundef %19, float noundef %8) #11
  %30 = tail call spir_func float @_Z3fmafff(float noundef %28, float noundef %24, float noundef %9) #11
  %31 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %13) #10
  %32 = trunc i32 %31 to i16
  %33 = bitcast i16 %32 to half
  %34 = fpext half %33 to float
  %35 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %19, float noundef %10) #11
  %36 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %24, float noundef %11) #11
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %15) #10
  %38 = lshr i32 %37, 16
  %39 = trunc nuw i32 %38 to i16
  %40 = bitcast i16 %39 to half
  %41 = fpext half %40 to float
  %42 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %20) #10
  %43 = lshr i32 %42, 16
  %44 = trunc nuw i32 %43 to i16
  %45 = bitcast i16 %44 to half
  %46 = fpext half %45 to float
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %13) #10
  %48 = lshr i32 %47, 16
  %49 = trunc nuw i32 %48 to i16
  %50 = bitcast i16 %49 to half
  %51 = fpext half %50 to float
  %52 = tail call spir_func float @_Z3fmafff(float noundef %51, float noundef %41, float noundef %29) #11
  %53 = tail call spir_func float @_Z3fmafff(float noundef %51, float noundef %46, float noundef %30) #11
  %54 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %13) #10
  %55 = lshr i32 %54, 16
  %56 = trunc nuw i32 %55 to i16
  %57 = bitcast i16 %56 to half
  %58 = fpext half %57 to float
  %59 = tail call spir_func float @_Z3fmafff(float noundef %58, float noundef %41, float noundef %35) #11
  %60 = tail call spir_func float @_Z3fmafff(float noundef %58, float noundef %46, float noundef %36) #11
  %61 = or disjoint i32 %15, 1
  %62 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %61) #10
  %63 = trunc i32 %62 to i16
  %64 = bitcast i16 %63 to half
  %65 = fpext half %64 to float
  %66 = or disjoint i32 %15, 5
  %67 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %66) #10
  %68 = trunc i32 %67 to i16
  %69 = bitcast i16 %68 to half
  %70 = fpext half %69 to float
  %71 = or disjoint i32 %13, 1
  %72 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %71) #10
  %73 = trunc i32 %72 to i16
  %74 = bitcast i16 %73 to half
  %75 = fpext half %74 to float
  %76 = tail call spir_func float @_Z3fmafff(float noundef %75, float noundef %65, float noundef %52) #11
  %77 = tail call spir_func float @_Z3fmafff(float noundef %75, float noundef %70, float noundef %53) #11
  %78 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %71) #10
  %79 = trunc i32 %78 to i16
  %80 = bitcast i16 %79 to half
  %81 = fpext half %80 to float
  %82 = tail call spir_func float @_Z3fmafff(float noundef %81, float noundef %65, float noundef %59) #11
  %83 = tail call spir_func float @_Z3fmafff(float noundef %81, float noundef %70, float noundef %60) #11
  %84 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %61) #10
  %85 = lshr i32 %84, 16
  %86 = trunc nuw i32 %85 to i16
  %87 = bitcast i16 %86 to half
  %88 = fpext half %87 to float
  %89 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %66) #10
  %90 = lshr i32 %89, 16
  %91 = trunc nuw i32 %90 to i16
  %92 = bitcast i16 %91 to half
  %93 = fpext half %92 to float
  %94 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %71) #10
  %95 = lshr i32 %94, 16
  %96 = trunc nuw i32 %95 to i16
  %97 = bitcast i16 %96 to half
  %98 = fpext half %97 to float
  %99 = tail call spir_func float @_Z3fmafff(float noundef %98, float noundef %88, float noundef %76) #11
  %100 = tail call spir_func float @_Z3fmafff(float noundef %98, float noundef %93, float noundef %77) #11
  %101 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %71) #10
  %102 = lshr i32 %101, 16
  %103 = trunc nuw i32 %102 to i16
  %104 = bitcast i16 %103 to half
  %105 = fpext half %104 to float
  %106 = tail call spir_func float @_Z3fmafff(float noundef %105, float noundef %88, float noundef %82) #11
  %107 = tail call spir_func float @_Z3fmafff(float noundef %105, float noundef %93, float noundef %83) #11
  %108 = or disjoint i32 %15, 2
  %109 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %108) #10
  %110 = trunc i32 %109 to i16
  %111 = bitcast i16 %110 to half
  %112 = fpext half %111 to float
  %113 = or disjoint i32 %15, 6
  %114 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %113) #10
  %115 = trunc i32 %114 to i16
  %116 = bitcast i16 %115 to half
  %117 = fpext half %116 to float
  %118 = or disjoint i32 %13, 2
  %119 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %118) #10
  %120 = trunc i32 %119 to i16
  %121 = bitcast i16 %120 to half
  %122 = fpext half %121 to float
  %123 = tail call spir_func float @_Z3fmafff(float noundef %122, float noundef %112, float noundef %99) #11
  %124 = tail call spir_func float @_Z3fmafff(float noundef %122, float noundef %117, float noundef %100) #11
  %125 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %118) #10
  %126 = trunc i32 %125 to i16
  %127 = bitcast i16 %126 to half
  %128 = fpext half %127 to float
  %129 = tail call spir_func float @_Z3fmafff(float noundef %128, float noundef %112, float noundef %106) #11
  %130 = tail call spir_func float @_Z3fmafff(float noundef %128, float noundef %117, float noundef %107) #11
  %131 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %108) #10
  %132 = lshr i32 %131, 16
  %133 = trunc nuw i32 %132 to i16
  %134 = bitcast i16 %133 to half
  %135 = fpext half %134 to float
  %136 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %113) #10
  %137 = lshr i32 %136, 16
  %138 = trunc nuw i32 %137 to i16
  %139 = bitcast i16 %138 to half
  %140 = fpext half %139 to float
  %141 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %118) #10
  %142 = lshr i32 %141, 16
  %143 = trunc nuw i32 %142 to i16
  %144 = bitcast i16 %143 to half
  %145 = fpext half %144 to float
  %146 = tail call spir_func float @_Z3fmafff(float noundef %145, float noundef %135, float noundef %123) #11
  %147 = tail call spir_func float @_Z3fmafff(float noundef %145, float noundef %140, float noundef %124) #11
  %148 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %118) #10
  %149 = lshr i32 %148, 16
  %150 = trunc nuw i32 %149 to i16
  %151 = bitcast i16 %150 to half
  %152 = fpext half %151 to float
  %153 = tail call spir_func float @_Z3fmafff(float noundef %152, float noundef %135, float noundef %129) #11
  %154 = tail call spir_func float @_Z3fmafff(float noundef %152, float noundef %140, float noundef %130) #11
  %155 = or disjoint i32 %15, 3
  %156 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %155) #10
  %157 = trunc i32 %156 to i16
  %158 = bitcast i16 %157 to half
  %159 = fpext half %158 to float
  %160 = or disjoint i32 %15, 7
  %161 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %160) #10
  %162 = trunc i32 %161 to i16
  %163 = bitcast i16 %162 to half
  %164 = fpext half %163 to float
  %165 = or i32 %12, 3
  %166 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %165) #10
  %167 = trunc i32 %166 to i16
  %168 = bitcast i16 %167 to half
  %169 = fpext half %168 to float
  %170 = tail call spir_func float @_Z3fmafff(float noundef %169, float noundef %159, float noundef %146) #11
  %171 = tail call spir_func float @_Z3fmafff(float noundef %169, float noundef %164, float noundef %147) #11
  %172 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %165) #10
  %173 = trunc i32 %172 to i16
  %174 = bitcast i16 %173 to half
  %175 = fpext half %174 to float
  %176 = tail call spir_func float @_Z3fmafff(float noundef %175, float noundef %159, float noundef %153) #11
  %177 = tail call spir_func float @_Z3fmafff(float noundef %175, float noundef %164, float noundef %154) #11
  %178 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %155) #10
  %179 = lshr i32 %178, 16
  %180 = trunc nuw i32 %179 to i16
  %181 = bitcast i16 %180 to half
  %182 = fpext half %181 to float
  %183 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %160) #10
  %184 = lshr i32 %183, 16
  %185 = trunc nuw i32 %184 to i16
  %186 = bitcast i16 %185 to half
  %187 = fpext half %186 to float
  %188 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %165) #10
  %189 = lshr i32 %188, 16
  %190 = trunc nuw i32 %189 to i16
  %191 = bitcast i16 %190 to half
  %192 = fpext half %191 to float
  %193 = tail call spir_func float @_Z3fmafff(float noundef %192, float noundef %182, float noundef %170) #11
  %194 = tail call spir_func float @_Z3fmafff(float noundef %192, float noundef %187, float noundef %171) #11
  %195 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %165) #10
  %196 = lshr i32 %195, 16
  %197 = trunc nuw i32 %196 to i16
  %198 = bitcast i16 %197 to half
  %199 = fpext half %198 to float
  %200 = tail call spir_func float @_Z3fmafff(float noundef %199, float noundef %182, float noundef %176) #11
  %201 = tail call spir_func float @_Z3fmafff(float noundef %199, float noundef %187, float noundef %177) #11
  %202 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %15) #10
  %203 = trunc i32 %202 to i16
  %204 = bitcast i16 %203 to half
  %205 = fpext half %204 to float
  %206 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %20) #10
  %207 = trunc i32 %206 to i16
  %208 = bitcast i16 %207 to half
  %209 = fpext half %208 to float
  %210 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %211 = trunc i32 %210 to i16
  %212 = bitcast i16 %211 to half
  %213 = fpext half %212 to float
  %214 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %205, float noundef %193) #11
  %215 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %209, float noundef %194) #11
  %216 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %13) #10
  %217 = trunc i32 %216 to i16
  %218 = bitcast i16 %217 to half
  %219 = fpext half %218 to float
  %220 = tail call spir_func float @_Z3fmafff(float noundef %219, float noundef %205, float noundef %200) #11
  %221 = tail call spir_func float @_Z3fmafff(float noundef %219, float noundef %209, float noundef %201) #11
  %222 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %15) #10
  %223 = lshr i32 %222, 16
  %224 = trunc nuw i32 %223 to i16
  %225 = bitcast i16 %224 to half
  %226 = fpext half %225 to float
  %227 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %20) #10
  %228 = lshr i32 %227, 16
  %229 = trunc nuw i32 %228 to i16
  %230 = bitcast i16 %229 to half
  %231 = fpext half %230 to float
  %232 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %233 = lshr i32 %232, 16
  %234 = trunc nuw i32 %233 to i16
  %235 = bitcast i16 %234 to half
  %236 = fpext half %235 to float
  %237 = tail call spir_func float @_Z3fmafff(float noundef %236, float noundef %226, float noundef %214) #11
  %238 = tail call spir_func float @_Z3fmafff(float noundef %236, float noundef %231, float noundef %215) #11
  %239 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %13) #10
  %240 = lshr i32 %239, 16
  %241 = trunc nuw i32 %240 to i16
  %242 = bitcast i16 %241 to half
  %243 = fpext half %242 to float
  %244 = tail call spir_func float @_Z3fmafff(float noundef %243, float noundef %226, float noundef %220) #11
  %245 = tail call spir_func float @_Z3fmafff(float noundef %243, float noundef %231, float noundef %221) #11
  %246 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %61) #10
  %247 = trunc i32 %246 to i16
  %248 = bitcast i16 %247 to half
  %249 = fpext half %248 to float
  %250 = or disjoint i32 %15, 5
  %251 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %250) #10
  %252 = trunc i32 %251 to i16
  %253 = bitcast i16 %252 to half
  %254 = fpext half %253 to float
  %255 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %71) #10
  %256 = trunc i32 %255 to i16
  %257 = bitcast i16 %256 to half
  %258 = fpext half %257 to float
  %259 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %249, float noundef %237) #11
  %260 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %254, float noundef %238) #11
  %261 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %71) #10
  %262 = trunc i32 %261 to i16
  %263 = bitcast i16 %262 to half
  %264 = fpext half %263 to float
  %265 = tail call spir_func float @_Z3fmafff(float noundef %264, float noundef %249, float noundef %244) #11
  %266 = tail call spir_func float @_Z3fmafff(float noundef %264, float noundef %254, float noundef %245) #11
  %267 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %61) #10
  %268 = lshr i32 %267, 16
  %269 = trunc nuw i32 %268 to i16
  %270 = bitcast i16 %269 to half
  %271 = fpext half %270 to float
  %272 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %250) #10
  %273 = lshr i32 %272, 16
  %274 = trunc nuw i32 %273 to i16
  %275 = bitcast i16 %274 to half
  %276 = fpext half %275 to float
  %277 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %71) #10
  %278 = lshr i32 %277, 16
  %279 = trunc nuw i32 %278 to i16
  %280 = bitcast i16 %279 to half
  %281 = fpext half %280 to float
  %282 = tail call spir_func float @_Z3fmafff(float noundef %281, float noundef %271, float noundef %259) #11
  %283 = tail call spir_func float @_Z3fmafff(float noundef %281, float noundef %276, float noundef %260) #11
  %284 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %71) #10
  %285 = lshr i32 %284, 16
  %286 = trunc nuw i32 %285 to i16
  %287 = bitcast i16 %286 to half
  %288 = fpext half %287 to float
  %289 = tail call spir_func float @_Z3fmafff(float noundef %288, float noundef %271, float noundef %265) #11
  %290 = tail call spir_func float @_Z3fmafff(float noundef %288, float noundef %276, float noundef %266) #11
  %291 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %108) #10
  %292 = trunc i32 %291 to i16
  %293 = bitcast i16 %292 to half
  %294 = fpext half %293 to float
  %295 = or disjoint i32 %15, 6
  %296 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %295) #10
  %297 = trunc i32 %296 to i16
  %298 = bitcast i16 %297 to half
  %299 = fpext half %298 to float
  %300 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %118) #10
  %301 = trunc i32 %300 to i16
  %302 = bitcast i16 %301 to half
  %303 = fpext half %302 to float
  %304 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %294, float noundef %282) #11
  %305 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %299, float noundef %283) #11
  %306 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %118) #10
  %307 = trunc i32 %306 to i16
  %308 = bitcast i16 %307 to half
  %309 = fpext half %308 to float
  %310 = tail call spir_func float @_Z3fmafff(float noundef %309, float noundef %294, float noundef %289) #11
  %311 = tail call spir_func float @_Z3fmafff(float noundef %309, float noundef %299, float noundef %290) #11
  %312 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %108) #10
  %313 = lshr i32 %312, 16
  %314 = trunc nuw i32 %313 to i16
  %315 = bitcast i16 %314 to half
  %316 = fpext half %315 to float
  %317 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %295) #10
  %318 = lshr i32 %317, 16
  %319 = trunc nuw i32 %318 to i16
  %320 = bitcast i16 %319 to half
  %321 = fpext half %320 to float
  %322 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %118) #10
  %323 = lshr i32 %322, 16
  %324 = trunc nuw i32 %323 to i16
  %325 = bitcast i16 %324 to half
  %326 = fpext half %325 to float
  %327 = tail call spir_func float @_Z3fmafff(float noundef %326, float noundef %316, float noundef %304) #11
  %328 = tail call spir_func float @_Z3fmafff(float noundef %326, float noundef %321, float noundef %305) #11
  %329 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %118) #10
  %330 = lshr i32 %329, 16
  %331 = trunc nuw i32 %330 to i16
  %332 = bitcast i16 %331 to half
  %333 = fpext half %332 to float
  %334 = tail call spir_func float @_Z3fmafff(float noundef %333, float noundef %316, float noundef %310) #11
  %335 = tail call spir_func float @_Z3fmafff(float noundef %333, float noundef %321, float noundef %311) #11
  %336 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %155) #10
  %337 = trunc i32 %336 to i16
  %338 = bitcast i16 %337 to half
  %339 = fpext half %338 to float
  %340 = or disjoint i32 %15, 7
  %341 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %340) #10
  %342 = trunc i32 %341 to i16
  %343 = bitcast i16 %342 to half
  %344 = fpext half %343 to float
  %345 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %165) #10
  %346 = trunc i32 %345 to i16
  %347 = bitcast i16 %346 to half
  %348 = fpext half %347 to float
  %349 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %339, float noundef %327) #11
  %350 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %344, float noundef %328) #11
  %351 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %165) #10
  %352 = trunc i32 %351 to i16
  %353 = bitcast i16 %352 to half
  %354 = fpext half %353 to float
  %355 = tail call spir_func float @_Z3fmafff(float noundef %354, float noundef %339, float noundef %334) #11
  %356 = tail call spir_func float @_Z3fmafff(float noundef %354, float noundef %344, float noundef %335) #11
  %357 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %155) #10
  %358 = lshr i32 %357, 16
  %359 = trunc nuw i32 %358 to i16
  %360 = bitcast i16 %359 to half
  %361 = fpext half %360 to float
  %362 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %340) #10
  %363 = lshr i32 %362, 16
  %364 = trunc nuw i32 %363 to i16
  %365 = bitcast i16 %364 to half
  %366 = fpext half %365 to float
  %367 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %165) #10
  %368 = lshr i32 %367, 16
  %369 = trunc nuw i32 %368 to i16
  %370 = bitcast i16 %369 to half
  %371 = fpext half %370 to float
  %372 = tail call spir_func float @_Z3fmafff(float noundef %371, float noundef %361, float noundef %349) #11
  %373 = tail call spir_func float @_Z3fmafff(float noundef %371, float noundef %366, float noundef %350) #11
  %374 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %165) #10
  %375 = lshr i32 %374, 16
  %376 = trunc nuw i32 %375 to i16
  %377 = bitcast i16 %376 to half
  %378 = fpext half %377 to float
  %379 = tail call spir_func float @_Z3fmafff(float noundef %378, float noundef %361, float noundef %355) #11
  %380 = tail call spir_func float @_Z3fmafff(float noundef %378, float noundef %366, float noundef %356) #11
  %381 = insertelement <4 x float> poison, float %372, i64 0
  %382 = insertelement <4 x float> %381, float %373, i64 1
  %383 = insertelement <4 x float> %382, float %379, i64 2
  %384 = insertelement <4 x float> %383, float %380, i64 3
  ret <4 x float> %384
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x float> @__zlift_mma_m16n8k8_f32_bf16(i32 noundef %0, i32 noundef %1, i32 noundef %2, <4 x float> noundef %3) local_unnamed_addr #0 {
  %5 = extractelement <4 x float> %3, i64 0
  %6 = extractelement <4 x float> %3, i64 1
  %7 = extractelement <4 x float> %3, i64 2
  %8 = extractelement <4 x float> %3, i64 3
  %9 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %10 = and i32 %9, -4
  %11 = shl i32 %9, 3
  %12 = and i32 %11, 24
  %13 = or disjoint i32 %12, 4
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %12) #10
  %15 = shl i32 %14, 16
  %16 = bitcast i32 %15 to float
  %17 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %18 = shl i32 %17, 16
  %19 = bitcast i32 %18 to float
  %20 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %21 = shl i32 %20, 16
  %22 = bitcast i32 %21 to float
  %23 = tail call spir_func float @_Z3fmafff(float noundef %22, float noundef %16, float noundef %5) #11
  %24 = tail call spir_func float @_Z3fmafff(float noundef %22, float noundef %19, float noundef %6) #11
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %26 = shl i32 %25, 16
  %27 = bitcast i32 %26 to float
  %28 = tail call spir_func float @_Z3fmafff(float noundef %27, float noundef %16, float noundef %7) #11
  %29 = tail call spir_func float @_Z3fmafff(float noundef %27, float noundef %19, float noundef %8) #11
  %30 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %12) #10
  %31 = and i32 %30, -65536
  %32 = bitcast i32 %31 to float
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %34 = and i32 %33, -65536
  %35 = bitcast i32 %34 to float
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %37 = and i32 %36, -65536
  %38 = bitcast i32 %37 to float
  %39 = tail call spir_func float @_Z3fmafff(float noundef %38, float noundef %32, float noundef %23) #11
  %40 = tail call spir_func float @_Z3fmafff(float noundef %38, float noundef %35, float noundef %24) #11
  %41 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %42 = and i32 %41, -65536
  %43 = bitcast i32 %42 to float
  %44 = tail call spir_func float @_Z3fmafff(float noundef %43, float noundef %32, float noundef %28) #11
  %45 = tail call spir_func float @_Z3fmafff(float noundef %43, float noundef %35, float noundef %29) #11
  %46 = or disjoint i32 %12, 1
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %46) #10
  %48 = shl i32 %47, 16
  %49 = bitcast i32 %48 to float
  %50 = or disjoint i32 %12, 5
  %51 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %50) #10
  %52 = shl i32 %51, 16
  %53 = bitcast i32 %52 to float
  %54 = or disjoint i32 %10, 1
  %55 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %54) #10
  %56 = shl i32 %55, 16
  %57 = bitcast i32 %56 to float
  %58 = tail call spir_func float @_Z3fmafff(float noundef %57, float noundef %49, float noundef %39) #11
  %59 = tail call spir_func float @_Z3fmafff(float noundef %57, float noundef %53, float noundef %40) #11
  %60 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %54) #10
  %61 = shl i32 %60, 16
  %62 = bitcast i32 %61 to float
  %63 = tail call spir_func float @_Z3fmafff(float noundef %62, float noundef %49, float noundef %44) #11
  %64 = tail call spir_func float @_Z3fmafff(float noundef %62, float noundef %53, float noundef %45) #11
  %65 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %46) #10
  %66 = and i32 %65, -65536
  %67 = bitcast i32 %66 to float
  %68 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %50) #10
  %69 = and i32 %68, -65536
  %70 = bitcast i32 %69 to float
  %71 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %54) #10
  %72 = and i32 %71, -65536
  %73 = bitcast i32 %72 to float
  %74 = tail call spir_func float @_Z3fmafff(float noundef %73, float noundef %67, float noundef %58) #11
  %75 = tail call spir_func float @_Z3fmafff(float noundef %73, float noundef %70, float noundef %59) #11
  %76 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %54) #10
  %77 = and i32 %76, -65536
  %78 = bitcast i32 %77 to float
  %79 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %67, float noundef %63) #11
  %80 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %70, float noundef %64) #11
  %81 = or disjoint i32 %12, 2
  %82 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %81) #10
  %83 = shl i32 %82, 16
  %84 = bitcast i32 %83 to float
  %85 = or disjoint i32 %12, 6
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %85) #10
  %87 = shl i32 %86, 16
  %88 = bitcast i32 %87 to float
  %89 = or disjoint i32 %10, 2
  %90 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %89) #10
  %91 = shl i32 %90, 16
  %92 = bitcast i32 %91 to float
  %93 = tail call spir_func float @_Z3fmafff(float noundef %92, float noundef %84, float noundef %74) #11
  %94 = tail call spir_func float @_Z3fmafff(float noundef %92, float noundef %88, float noundef %75) #11
  %95 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %89) #10
  %96 = shl i32 %95, 16
  %97 = bitcast i32 %96 to float
  %98 = tail call spir_func float @_Z3fmafff(float noundef %97, float noundef %84, float noundef %79) #11
  %99 = tail call spir_func float @_Z3fmafff(float noundef %97, float noundef %88, float noundef %80) #11
  %100 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %81) #10
  %101 = and i32 %100, -65536
  %102 = bitcast i32 %101 to float
  %103 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %85) #10
  %104 = and i32 %103, -65536
  %105 = bitcast i32 %104 to float
  %106 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %89) #10
  %107 = and i32 %106, -65536
  %108 = bitcast i32 %107 to float
  %109 = tail call spir_func float @_Z3fmafff(float noundef %108, float noundef %102, float noundef %93) #11
  %110 = tail call spir_func float @_Z3fmafff(float noundef %108, float noundef %105, float noundef %94) #11
  %111 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %89) #10
  %112 = and i32 %111, -65536
  %113 = bitcast i32 %112 to float
  %114 = tail call spir_func float @_Z3fmafff(float noundef %113, float noundef %102, float noundef %98) #11
  %115 = tail call spir_func float @_Z3fmafff(float noundef %113, float noundef %105, float noundef %99) #11
  %116 = or disjoint i32 %12, 3
  %117 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %116) #10
  %118 = shl i32 %117, 16
  %119 = bitcast i32 %118 to float
  %120 = or disjoint i32 %12, 7
  %121 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %120) #10
  %122 = shl i32 %121, 16
  %123 = bitcast i32 %122 to float
  %124 = or i32 %9, 3
  %125 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %124) #10
  %126 = shl i32 %125, 16
  %127 = bitcast i32 %126 to float
  %128 = tail call spir_func float @_Z3fmafff(float noundef %127, float noundef %119, float noundef %109) #11
  %129 = tail call spir_func float @_Z3fmafff(float noundef %127, float noundef %123, float noundef %110) #11
  %130 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %124) #10
  %131 = shl i32 %130, 16
  %132 = bitcast i32 %131 to float
  %133 = tail call spir_func float @_Z3fmafff(float noundef %132, float noundef %119, float noundef %114) #11
  %134 = tail call spir_func float @_Z3fmafff(float noundef %132, float noundef %123, float noundef %115) #11
  %135 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %116) #10
  %136 = and i32 %135, -65536
  %137 = bitcast i32 %136 to float
  %138 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %120) #10
  %139 = and i32 %138, -65536
  %140 = bitcast i32 %139 to float
  %141 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %124) #10
  %142 = and i32 %141, -65536
  %143 = bitcast i32 %142 to float
  %144 = tail call spir_func float @_Z3fmafff(float noundef %143, float noundef %137, float noundef %128) #11
  %145 = tail call spir_func float @_Z3fmafff(float noundef %143, float noundef %140, float noundef %129) #11
  %146 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %124) #10
  %147 = and i32 %146, -65536
  %148 = bitcast i32 %147 to float
  %149 = tail call spir_func float @_Z3fmafff(float noundef %148, float noundef %137, float noundef %133) #11
  %150 = tail call spir_func float @_Z3fmafff(float noundef %148, float noundef %140, float noundef %134) #11
  %151 = insertelement <4 x float> poison, float %144, i64 0
  %152 = insertelement <4 x float> %151, float %145, i64 1
  %153 = insertelement <4 x float> %152, float %149, i64 2
  %154 = insertelement <4 x float> %153, float %150, i64 3
  ret <4 x float> %154
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x float> @__zlift_mma_m16n8k16_f32_bf16(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, <4 x float> noundef %6) local_unnamed_addr #0 {
  %8 = extractelement <4 x float> %6, i64 0
  %9 = extractelement <4 x float> %6, i64 1
  %10 = extractelement <4 x float> %6, i64 2
  %11 = extractelement <4 x float> %6, i64 3
  %12 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %13 = and i32 %12, -4
  %14 = shl i32 %12, 3
  %15 = and i32 %14, 24
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %15) #10
  %17 = shl i32 %16, 16
  %18 = bitcast i32 %17 to float
  %19 = or disjoint i32 %15, 4
  %20 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %19) #10
  %21 = shl i32 %20, 16
  %22 = bitcast i32 %21 to float
  %23 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %13) #10
  %24 = shl i32 %23, 16
  %25 = bitcast i32 %24 to float
  %26 = tail call spir_func float @_Z3fmafff(float noundef %25, float noundef %18, float noundef %8) #11
  %27 = tail call spir_func float @_Z3fmafff(float noundef %25, float noundef %22, float noundef %9) #11
  %28 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %13) #10
  %29 = shl i32 %28, 16
  %30 = bitcast i32 %29 to float
  %31 = tail call spir_func float @_Z3fmafff(float noundef %30, float noundef %18, float noundef %10) #11
  %32 = tail call spir_func float @_Z3fmafff(float noundef %30, float noundef %22, float noundef %11) #11
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %15) #10
  %34 = and i32 %33, -65536
  %35 = bitcast i32 %34 to float
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %19) #10
  %37 = and i32 %36, -65536
  %38 = bitcast i32 %37 to float
  %39 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %13) #10
  %40 = and i32 %39, -65536
  %41 = bitcast i32 %40 to float
  %42 = tail call spir_func float @_Z3fmafff(float noundef %41, float noundef %35, float noundef %26) #11
  %43 = tail call spir_func float @_Z3fmafff(float noundef %41, float noundef %38, float noundef %27) #11
  %44 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %13) #10
  %45 = and i32 %44, -65536
  %46 = bitcast i32 %45 to float
  %47 = tail call spir_func float @_Z3fmafff(float noundef %46, float noundef %35, float noundef %31) #11
  %48 = tail call spir_func float @_Z3fmafff(float noundef %46, float noundef %38, float noundef %32) #11
  %49 = or disjoint i32 %15, 1
  %50 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %49) #10
  %51 = shl i32 %50, 16
  %52 = bitcast i32 %51 to float
  %53 = or disjoint i32 %15, 5
  %54 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %53) #10
  %55 = shl i32 %54, 16
  %56 = bitcast i32 %55 to float
  %57 = or disjoint i32 %13, 1
  %58 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %57) #10
  %59 = shl i32 %58, 16
  %60 = bitcast i32 %59 to float
  %61 = tail call spir_func float @_Z3fmafff(float noundef %60, float noundef %52, float noundef %42) #11
  %62 = tail call spir_func float @_Z3fmafff(float noundef %60, float noundef %56, float noundef %43) #11
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %57) #10
  %64 = shl i32 %63, 16
  %65 = bitcast i32 %64 to float
  %66 = tail call spir_func float @_Z3fmafff(float noundef %65, float noundef %52, float noundef %47) #11
  %67 = tail call spir_func float @_Z3fmafff(float noundef %65, float noundef %56, float noundef %48) #11
  %68 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %49) #10
  %69 = and i32 %68, -65536
  %70 = bitcast i32 %69 to float
  %71 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %53) #10
  %72 = and i32 %71, -65536
  %73 = bitcast i32 %72 to float
  %74 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %57) #10
  %75 = and i32 %74, -65536
  %76 = bitcast i32 %75 to float
  %77 = tail call spir_func float @_Z3fmafff(float noundef %76, float noundef %70, float noundef %61) #11
  %78 = tail call spir_func float @_Z3fmafff(float noundef %76, float noundef %73, float noundef %62) #11
  %79 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %57) #10
  %80 = and i32 %79, -65536
  %81 = bitcast i32 %80 to float
  %82 = tail call spir_func float @_Z3fmafff(float noundef %81, float noundef %70, float noundef %66) #11
  %83 = tail call spir_func float @_Z3fmafff(float noundef %81, float noundef %73, float noundef %67) #11
  %84 = or disjoint i32 %15, 2
  %85 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %84) #10
  %86 = shl i32 %85, 16
  %87 = bitcast i32 %86 to float
  %88 = or disjoint i32 %15, 6
  %89 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %88) #10
  %90 = shl i32 %89, 16
  %91 = bitcast i32 %90 to float
  %92 = or disjoint i32 %13, 2
  %93 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %92) #10
  %94 = shl i32 %93, 16
  %95 = bitcast i32 %94 to float
  %96 = tail call spir_func float @_Z3fmafff(float noundef %95, float noundef %87, float noundef %77) #11
  %97 = tail call spir_func float @_Z3fmafff(float noundef %95, float noundef %91, float noundef %78) #11
  %98 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %92) #10
  %99 = shl i32 %98, 16
  %100 = bitcast i32 %99 to float
  %101 = tail call spir_func float @_Z3fmafff(float noundef %100, float noundef %87, float noundef %82) #11
  %102 = tail call spir_func float @_Z3fmafff(float noundef %100, float noundef %91, float noundef %83) #11
  %103 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %84) #10
  %104 = and i32 %103, -65536
  %105 = bitcast i32 %104 to float
  %106 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %88) #10
  %107 = and i32 %106, -65536
  %108 = bitcast i32 %107 to float
  %109 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %92) #10
  %110 = and i32 %109, -65536
  %111 = bitcast i32 %110 to float
  %112 = tail call spir_func float @_Z3fmafff(float noundef %111, float noundef %105, float noundef %96) #11
  %113 = tail call spir_func float @_Z3fmafff(float noundef %111, float noundef %108, float noundef %97) #11
  %114 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %92) #10
  %115 = and i32 %114, -65536
  %116 = bitcast i32 %115 to float
  %117 = tail call spir_func float @_Z3fmafff(float noundef %116, float noundef %105, float noundef %101) #11
  %118 = tail call spir_func float @_Z3fmafff(float noundef %116, float noundef %108, float noundef %102) #11
  %119 = or disjoint i32 %15, 3
  %120 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %119) #10
  %121 = shl i32 %120, 16
  %122 = bitcast i32 %121 to float
  %123 = or disjoint i32 %15, 7
  %124 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %123) #10
  %125 = shl i32 %124, 16
  %126 = bitcast i32 %125 to float
  %127 = or i32 %12, 3
  %128 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %127) #10
  %129 = shl i32 %128, 16
  %130 = bitcast i32 %129 to float
  %131 = tail call spir_func float @_Z3fmafff(float noundef %130, float noundef %122, float noundef %112) #11
  %132 = tail call spir_func float @_Z3fmafff(float noundef %130, float noundef %126, float noundef %113) #11
  %133 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %127) #10
  %134 = shl i32 %133, 16
  %135 = bitcast i32 %134 to float
  %136 = tail call spir_func float @_Z3fmafff(float noundef %135, float noundef %122, float noundef %117) #11
  %137 = tail call spir_func float @_Z3fmafff(float noundef %135, float noundef %126, float noundef %118) #11
  %138 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %119) #10
  %139 = and i32 %138, -65536
  %140 = bitcast i32 %139 to float
  %141 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %123) #10
  %142 = and i32 %141, -65536
  %143 = bitcast i32 %142 to float
  %144 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %127) #10
  %145 = and i32 %144, -65536
  %146 = bitcast i32 %145 to float
  %147 = tail call spir_func float @_Z3fmafff(float noundef %146, float noundef %140, float noundef %131) #11
  %148 = tail call spir_func float @_Z3fmafff(float noundef %146, float noundef %143, float noundef %132) #11
  %149 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %127) #10
  %150 = and i32 %149, -65536
  %151 = bitcast i32 %150 to float
  %152 = tail call spir_func float @_Z3fmafff(float noundef %151, float noundef %140, float noundef %136) #11
  %153 = tail call spir_func float @_Z3fmafff(float noundef %151, float noundef %143, float noundef %137) #11
  %154 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %15) #10
  %155 = shl i32 %154, 16
  %156 = bitcast i32 %155 to float
  %157 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %19) #10
  %158 = shl i32 %157, 16
  %159 = bitcast i32 %158 to float
  %160 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %161 = shl i32 %160, 16
  %162 = bitcast i32 %161 to float
  %163 = tail call spir_func float @_Z3fmafff(float noundef %162, float noundef %156, float noundef %147) #11
  %164 = tail call spir_func float @_Z3fmafff(float noundef %162, float noundef %159, float noundef %148) #11
  %165 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %13) #10
  %166 = shl i32 %165, 16
  %167 = bitcast i32 %166 to float
  %168 = tail call spir_func float @_Z3fmafff(float noundef %167, float noundef %156, float noundef %152) #11
  %169 = tail call spir_func float @_Z3fmafff(float noundef %167, float noundef %159, float noundef %153) #11
  %170 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %15) #10
  %171 = and i32 %170, -65536
  %172 = bitcast i32 %171 to float
  %173 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %19) #10
  %174 = and i32 %173, -65536
  %175 = bitcast i32 %174 to float
  %176 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %177 = and i32 %176, -65536
  %178 = bitcast i32 %177 to float
  %179 = tail call spir_func float @_Z3fmafff(float noundef %178, float noundef %172, float noundef %163) #11
  %180 = tail call spir_func float @_Z3fmafff(float noundef %178, float noundef %175, float noundef %164) #11
  %181 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %13) #10
  %182 = and i32 %181, -65536
  %183 = bitcast i32 %182 to float
  %184 = tail call spir_func float @_Z3fmafff(float noundef %183, float noundef %172, float noundef %168) #11
  %185 = tail call spir_func float @_Z3fmafff(float noundef %183, float noundef %175, float noundef %169) #11
  %186 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %49) #10
  %187 = shl i32 %186, 16
  %188 = bitcast i32 %187 to float
  %189 = or disjoint i32 %15, 5
  %190 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %189) #10
  %191 = shl i32 %190, 16
  %192 = bitcast i32 %191 to float
  %193 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %57) #10
  %194 = shl i32 %193, 16
  %195 = bitcast i32 %194 to float
  %196 = tail call spir_func float @_Z3fmafff(float noundef %195, float noundef %188, float noundef %179) #11
  %197 = tail call spir_func float @_Z3fmafff(float noundef %195, float noundef %192, float noundef %180) #11
  %198 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %57) #10
  %199 = shl i32 %198, 16
  %200 = bitcast i32 %199 to float
  %201 = tail call spir_func float @_Z3fmafff(float noundef %200, float noundef %188, float noundef %184) #11
  %202 = tail call spir_func float @_Z3fmafff(float noundef %200, float noundef %192, float noundef %185) #11
  %203 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %49) #10
  %204 = and i32 %203, -65536
  %205 = bitcast i32 %204 to float
  %206 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %189) #10
  %207 = and i32 %206, -65536
  %208 = bitcast i32 %207 to float
  %209 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %57) #10
  %210 = and i32 %209, -65536
  %211 = bitcast i32 %210 to float
  %212 = tail call spir_func float @_Z3fmafff(float noundef %211, float noundef %205, float noundef %196) #11
  %213 = tail call spir_func float @_Z3fmafff(float noundef %211, float noundef %208, float noundef %197) #11
  %214 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %57) #10
  %215 = and i32 %214, -65536
  %216 = bitcast i32 %215 to float
  %217 = tail call spir_func float @_Z3fmafff(float noundef %216, float noundef %205, float noundef %201) #11
  %218 = tail call spir_func float @_Z3fmafff(float noundef %216, float noundef %208, float noundef %202) #11
  %219 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %84) #10
  %220 = shl i32 %219, 16
  %221 = bitcast i32 %220 to float
  %222 = or disjoint i32 %15, 6
  %223 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %222) #10
  %224 = shl i32 %223, 16
  %225 = bitcast i32 %224 to float
  %226 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %92) #10
  %227 = shl i32 %226, 16
  %228 = bitcast i32 %227 to float
  %229 = tail call spir_func float @_Z3fmafff(float noundef %228, float noundef %221, float noundef %212) #11
  %230 = tail call spir_func float @_Z3fmafff(float noundef %228, float noundef %225, float noundef %213) #11
  %231 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %92) #10
  %232 = shl i32 %231, 16
  %233 = bitcast i32 %232 to float
  %234 = tail call spir_func float @_Z3fmafff(float noundef %233, float noundef %221, float noundef %217) #11
  %235 = tail call spir_func float @_Z3fmafff(float noundef %233, float noundef %225, float noundef %218) #11
  %236 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %84) #10
  %237 = and i32 %236, -65536
  %238 = bitcast i32 %237 to float
  %239 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %222) #10
  %240 = and i32 %239, -65536
  %241 = bitcast i32 %240 to float
  %242 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %92) #10
  %243 = and i32 %242, -65536
  %244 = bitcast i32 %243 to float
  %245 = tail call spir_func float @_Z3fmafff(float noundef %244, float noundef %238, float noundef %229) #11
  %246 = tail call spir_func float @_Z3fmafff(float noundef %244, float noundef %241, float noundef %230) #11
  %247 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %92) #10
  %248 = and i32 %247, -65536
  %249 = bitcast i32 %248 to float
  %250 = tail call spir_func float @_Z3fmafff(float noundef %249, float noundef %238, float noundef %234) #11
  %251 = tail call spir_func float @_Z3fmafff(float noundef %249, float noundef %241, float noundef %235) #11
  %252 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %119) #10
  %253 = shl i32 %252, 16
  %254 = bitcast i32 %253 to float
  %255 = or disjoint i32 %15, 7
  %256 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %255) #10
  %257 = shl i32 %256, 16
  %258 = bitcast i32 %257 to float
  %259 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %127) #10
  %260 = shl i32 %259, 16
  %261 = bitcast i32 %260 to float
  %262 = tail call spir_func float @_Z3fmafff(float noundef %261, float noundef %254, float noundef %245) #11
  %263 = tail call spir_func float @_Z3fmafff(float noundef %261, float noundef %258, float noundef %246) #11
  %264 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %127) #10
  %265 = shl i32 %264, 16
  %266 = bitcast i32 %265 to float
  %267 = tail call spir_func float @_Z3fmafff(float noundef %266, float noundef %254, float noundef %250) #11
  %268 = tail call spir_func float @_Z3fmafff(float noundef %266, float noundef %258, float noundef %251) #11
  %269 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %119) #10
  %270 = and i32 %269, -65536
  %271 = bitcast i32 %270 to float
  %272 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %255) #10
  %273 = and i32 %272, -65536
  %274 = bitcast i32 %273 to float
  %275 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %127) #10
  %276 = and i32 %275, -65536
  %277 = bitcast i32 %276 to float
  %278 = tail call spir_func float @_Z3fmafff(float noundef %277, float noundef %271, float noundef %262) #11
  %279 = tail call spir_func float @_Z3fmafff(float noundef %277, float noundef %274, float noundef %263) #11
  %280 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %127) #10
  %281 = and i32 %280, -65536
  %282 = bitcast i32 %281 to float
  %283 = tail call spir_func float @_Z3fmafff(float noundef %282, float noundef %271, float noundef %267) #11
  %284 = tail call spir_func float @_Z3fmafff(float noundef %282, float noundef %274, float noundef %268) #11
  %285 = insertelement <4 x float> poison, float %278, i64 0
  %286 = insertelement <4 x float> %285, float %279, i64 1
  %287 = insertelement <4 x float> %286, float %283, i64 2
  %288 = insertelement <4 x float> %287, float %284, i64 3
  ret <4 x float> %288
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zlift_mma_m16n8k8_f16_f16(i32 noundef %0, i32 noundef %1, i32 noundef %2, <2 x i32> noundef %3) local_unnamed_addr #0 {
  %5 = extractelement <2 x i32> %3, i64 0
  %6 = bitcast i32 %5 to <2 x half>
  %7 = extractelement <2 x half> %6, i64 0
  %8 = fpext half %7 to float
  %9 = extractelement <2 x half> %6, i64 1
  %10 = fpext half %9 to float
  %11 = extractelement <2 x i32> %3, i64 1
  %12 = bitcast i32 %11 to <2 x half>
  %13 = extractelement <2 x half> %12, i64 0
  %14 = fpext half %13 to float
  %15 = extractelement <2 x half> %12, i64 1
  %16 = fpext half %15 to float
  %17 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %18 = and i32 %17, -4
  %19 = shl i32 %17, 3
  %20 = and i32 %19, 24
  %21 = or disjoint i32 %20, 4
  %22 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %20) #10
  %23 = trunc i32 %22 to i16
  %24 = bitcast i16 %23 to half
  %25 = fpext half %24 to float
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %21) #10
  %27 = trunc i32 %26 to i16
  %28 = bitcast i16 %27 to half
  %29 = fpext half %28 to float
  %30 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %18) #10
  %31 = trunc i32 %30 to i16
  %32 = bitcast i16 %31 to half
  %33 = fpext half %32 to float
  %34 = tail call spir_func float @_Z3fmafff(float noundef %33, float noundef %25, float noundef %8) #11
  %35 = tail call spir_func float @_Z3fmafff(float noundef %33, float noundef %29, float noundef %10) #11
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %18) #10
  %37 = trunc i32 %36 to i16
  %38 = bitcast i16 %37 to half
  %39 = fpext half %38 to float
  %40 = tail call spir_func float @_Z3fmafff(float noundef %39, float noundef %25, float noundef %14) #11
  %41 = tail call spir_func float @_Z3fmafff(float noundef %39, float noundef %29, float noundef %16) #11
  %42 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %20) #10
  %43 = lshr i32 %42, 16
  %44 = trunc nuw i32 %43 to i16
  %45 = bitcast i16 %44 to half
  %46 = fpext half %45 to float
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %21) #10
  %48 = lshr i32 %47, 16
  %49 = trunc nuw i32 %48 to i16
  %50 = bitcast i16 %49 to half
  %51 = fpext half %50 to float
  %52 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %18) #10
  %53 = lshr i32 %52, 16
  %54 = trunc nuw i32 %53 to i16
  %55 = bitcast i16 %54 to half
  %56 = fpext half %55 to float
  %57 = tail call spir_func float @_Z3fmafff(float noundef %56, float noundef %46, float noundef %34) #11
  %58 = tail call spir_func float @_Z3fmafff(float noundef %56, float noundef %51, float noundef %35) #11
  %59 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %18) #10
  %60 = lshr i32 %59, 16
  %61 = trunc nuw i32 %60 to i16
  %62 = bitcast i16 %61 to half
  %63 = fpext half %62 to float
  %64 = tail call spir_func float @_Z3fmafff(float noundef %63, float noundef %46, float noundef %40) #11
  %65 = tail call spir_func float @_Z3fmafff(float noundef %63, float noundef %51, float noundef %41) #11
  %66 = or disjoint i32 %20, 1
  %67 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %66) #10
  %68 = trunc i32 %67 to i16
  %69 = bitcast i16 %68 to half
  %70 = fpext half %69 to float
  %71 = or disjoint i32 %20, 5
  %72 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %71) #10
  %73 = trunc i32 %72 to i16
  %74 = bitcast i16 %73 to half
  %75 = fpext half %74 to float
  %76 = or disjoint i32 %18, 1
  %77 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %76) #10
  %78 = trunc i32 %77 to i16
  %79 = bitcast i16 %78 to half
  %80 = fpext half %79 to float
  %81 = tail call spir_func float @_Z3fmafff(float noundef %80, float noundef %70, float noundef %57) #11
  %82 = tail call spir_func float @_Z3fmafff(float noundef %80, float noundef %75, float noundef %58) #11
  %83 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %76) #10
  %84 = trunc i32 %83 to i16
  %85 = bitcast i16 %84 to half
  %86 = fpext half %85 to float
  %87 = tail call spir_func float @_Z3fmafff(float noundef %86, float noundef %70, float noundef %64) #11
  %88 = tail call spir_func float @_Z3fmafff(float noundef %86, float noundef %75, float noundef %65) #11
  %89 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %66) #10
  %90 = lshr i32 %89, 16
  %91 = trunc nuw i32 %90 to i16
  %92 = bitcast i16 %91 to half
  %93 = fpext half %92 to float
  %94 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %71) #10
  %95 = lshr i32 %94, 16
  %96 = trunc nuw i32 %95 to i16
  %97 = bitcast i16 %96 to half
  %98 = fpext half %97 to float
  %99 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %76) #10
  %100 = lshr i32 %99, 16
  %101 = trunc nuw i32 %100 to i16
  %102 = bitcast i16 %101 to half
  %103 = fpext half %102 to float
  %104 = tail call spir_func float @_Z3fmafff(float noundef %103, float noundef %93, float noundef %81) #11
  %105 = tail call spir_func float @_Z3fmafff(float noundef %103, float noundef %98, float noundef %82) #11
  %106 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %76) #10
  %107 = lshr i32 %106, 16
  %108 = trunc nuw i32 %107 to i16
  %109 = bitcast i16 %108 to half
  %110 = fpext half %109 to float
  %111 = tail call spir_func float @_Z3fmafff(float noundef %110, float noundef %93, float noundef %87) #11
  %112 = tail call spir_func float @_Z3fmafff(float noundef %110, float noundef %98, float noundef %88) #11
  %113 = or disjoint i32 %20, 2
  %114 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %113) #10
  %115 = trunc i32 %114 to i16
  %116 = bitcast i16 %115 to half
  %117 = fpext half %116 to float
  %118 = or disjoint i32 %20, 6
  %119 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %118) #10
  %120 = trunc i32 %119 to i16
  %121 = bitcast i16 %120 to half
  %122 = fpext half %121 to float
  %123 = or disjoint i32 %18, 2
  %124 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %123) #10
  %125 = trunc i32 %124 to i16
  %126 = bitcast i16 %125 to half
  %127 = fpext half %126 to float
  %128 = tail call spir_func float @_Z3fmafff(float noundef %127, float noundef %117, float noundef %104) #11
  %129 = tail call spir_func float @_Z3fmafff(float noundef %127, float noundef %122, float noundef %105) #11
  %130 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %123) #10
  %131 = trunc i32 %130 to i16
  %132 = bitcast i16 %131 to half
  %133 = fpext half %132 to float
  %134 = tail call spir_func float @_Z3fmafff(float noundef %133, float noundef %117, float noundef %111) #11
  %135 = tail call spir_func float @_Z3fmafff(float noundef %133, float noundef %122, float noundef %112) #11
  %136 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %113) #10
  %137 = lshr i32 %136, 16
  %138 = trunc nuw i32 %137 to i16
  %139 = bitcast i16 %138 to half
  %140 = fpext half %139 to float
  %141 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %118) #10
  %142 = lshr i32 %141, 16
  %143 = trunc nuw i32 %142 to i16
  %144 = bitcast i16 %143 to half
  %145 = fpext half %144 to float
  %146 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %123) #10
  %147 = lshr i32 %146, 16
  %148 = trunc nuw i32 %147 to i16
  %149 = bitcast i16 %148 to half
  %150 = fpext half %149 to float
  %151 = tail call spir_func float @_Z3fmafff(float noundef %150, float noundef %140, float noundef %128) #11
  %152 = tail call spir_func float @_Z3fmafff(float noundef %150, float noundef %145, float noundef %129) #11
  %153 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %123) #10
  %154 = lshr i32 %153, 16
  %155 = trunc nuw i32 %154 to i16
  %156 = bitcast i16 %155 to half
  %157 = fpext half %156 to float
  %158 = tail call spir_func float @_Z3fmafff(float noundef %157, float noundef %140, float noundef %134) #11
  %159 = tail call spir_func float @_Z3fmafff(float noundef %157, float noundef %145, float noundef %135) #11
  %160 = or disjoint i32 %20, 3
  %161 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %160) #10
  %162 = trunc i32 %161 to i16
  %163 = bitcast i16 %162 to half
  %164 = fpext half %163 to float
  %165 = or disjoint i32 %20, 7
  %166 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %165) #10
  %167 = trunc i32 %166 to i16
  %168 = bitcast i16 %167 to half
  %169 = fpext half %168 to float
  %170 = or i32 %17, 3
  %171 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %170) #10
  %172 = trunc i32 %171 to i16
  %173 = bitcast i16 %172 to half
  %174 = fpext half %173 to float
  %175 = tail call spir_func float @_Z3fmafff(float noundef %174, float noundef %164, float noundef %151) #11
  %176 = tail call spir_func float @_Z3fmafff(float noundef %174, float noundef %169, float noundef %152) #11
  %177 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %170) #10
  %178 = trunc i32 %177 to i16
  %179 = bitcast i16 %178 to half
  %180 = fpext half %179 to float
  %181 = tail call spir_func float @_Z3fmafff(float noundef %180, float noundef %164, float noundef %158) #11
  %182 = tail call spir_func float @_Z3fmafff(float noundef %180, float noundef %169, float noundef %159) #11
  %183 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %160) #10
  %184 = lshr i32 %183, 16
  %185 = trunc nuw i32 %184 to i16
  %186 = bitcast i16 %185 to half
  %187 = fpext half %186 to float
  %188 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %165) #10
  %189 = lshr i32 %188, 16
  %190 = trunc nuw i32 %189 to i16
  %191 = bitcast i16 %190 to half
  %192 = fpext half %191 to float
  %193 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %170) #10
  %194 = lshr i32 %193, 16
  %195 = trunc nuw i32 %194 to i16
  %196 = bitcast i16 %195 to half
  %197 = fpext half %196 to float
  %198 = tail call spir_func float @_Z3fmafff(float noundef %197, float noundef %187, float noundef %175) #11
  %199 = tail call spir_func float @_Z3fmafff(float noundef %197, float noundef %192, float noundef %176) #11
  %200 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %170) #10
  %201 = lshr i32 %200, 16
  %202 = trunc nuw i32 %201 to i16
  %203 = bitcast i16 %202 to half
  %204 = fpext half %203 to float
  %205 = tail call spir_func float @_Z3fmafff(float noundef %204, float noundef %187, float noundef %181) #11
  %206 = tail call spir_func float @_Z3fmafff(float noundef %204, float noundef %192, float noundef %182) #11
  %207 = tail call spir_func half @_Z12convert_halff(float noundef %198) #11
  %208 = insertelement <2 x half> poison, half %207, i64 0
  %209 = tail call spir_func half @_Z12convert_halff(float noundef %199) #11
  %210 = insertelement <2 x half> %208, half %209, i64 1
  %211 = bitcast <2 x half> %210 to i32
  %212 = insertelement <2 x i32> poison, i32 %211, i64 0
  %213 = tail call spir_func half @_Z12convert_halff(float noundef %205) #11
  %214 = insertelement <2 x half> poison, half %213, i64 0
  %215 = tail call spir_func half @_Z12convert_halff(float noundef %206) #11
  %216 = insertelement <2 x half> %214, half %215, i64 1
  %217 = bitcast <2 x half> %216 to i32
  %218 = insertelement <2 x i32> %212, i32 %217, i64 1
  ret <2 x i32> %218
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func half @_Z12convert_halff(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zlift_mma_m16n8k16_f16_f16(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, <2 x i32> noundef %6) local_unnamed_addr #0 {
  %8 = extractelement <2 x i32> %6, i64 0
  %9 = bitcast i32 %8 to <2 x half>
  %10 = extractelement <2 x half> %9, i64 0
  %11 = fpext half %10 to float
  %12 = extractelement <2 x half> %9, i64 1
  %13 = fpext half %12 to float
  %14 = extractelement <2 x i32> %6, i64 1
  %15 = bitcast i32 %14 to <2 x half>
  %16 = extractelement <2 x half> %15, i64 0
  %17 = fpext half %16 to float
  %18 = extractelement <2 x half> %15, i64 1
  %19 = fpext half %18 to float
  %20 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %21 = and i32 %20, -4
  %22 = shl i32 %20, 3
  %23 = and i32 %22, 24
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %23) #10
  %25 = trunc i32 %24 to i16
  %26 = bitcast i16 %25 to half
  %27 = fpext half %26 to float
  %28 = or disjoint i32 %23, 4
  %29 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %28) #10
  %30 = trunc i32 %29 to i16
  %31 = bitcast i16 %30 to half
  %32 = fpext half %31 to float
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %21) #10
  %34 = trunc i32 %33 to i16
  %35 = bitcast i16 %34 to half
  %36 = fpext half %35 to float
  %37 = tail call spir_func float @_Z3fmafff(float noundef %36, float noundef %27, float noundef %11) #11
  %38 = tail call spir_func float @_Z3fmafff(float noundef %36, float noundef %32, float noundef %13) #11
  %39 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %21) #10
  %40 = trunc i32 %39 to i16
  %41 = bitcast i16 %40 to half
  %42 = fpext half %41 to float
  %43 = tail call spir_func float @_Z3fmafff(float noundef %42, float noundef %27, float noundef %17) #11
  %44 = tail call spir_func float @_Z3fmafff(float noundef %42, float noundef %32, float noundef %19) #11
  %45 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %23) #10
  %46 = lshr i32 %45, 16
  %47 = trunc nuw i32 %46 to i16
  %48 = bitcast i16 %47 to half
  %49 = fpext half %48 to float
  %50 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %28) #10
  %51 = lshr i32 %50, 16
  %52 = trunc nuw i32 %51 to i16
  %53 = bitcast i16 %52 to half
  %54 = fpext half %53 to float
  %55 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %21) #10
  %56 = lshr i32 %55, 16
  %57 = trunc nuw i32 %56 to i16
  %58 = bitcast i16 %57 to half
  %59 = fpext half %58 to float
  %60 = tail call spir_func float @_Z3fmafff(float noundef %59, float noundef %49, float noundef %37) #11
  %61 = tail call spir_func float @_Z3fmafff(float noundef %59, float noundef %54, float noundef %38) #11
  %62 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %21) #10
  %63 = lshr i32 %62, 16
  %64 = trunc nuw i32 %63 to i16
  %65 = bitcast i16 %64 to half
  %66 = fpext half %65 to float
  %67 = tail call spir_func float @_Z3fmafff(float noundef %66, float noundef %49, float noundef %43) #11
  %68 = tail call spir_func float @_Z3fmafff(float noundef %66, float noundef %54, float noundef %44) #11
  %69 = or disjoint i32 %23, 1
  %70 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %69) #10
  %71 = trunc i32 %70 to i16
  %72 = bitcast i16 %71 to half
  %73 = fpext half %72 to float
  %74 = or disjoint i32 %23, 5
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %74) #10
  %76 = trunc i32 %75 to i16
  %77 = bitcast i16 %76 to half
  %78 = fpext half %77 to float
  %79 = or disjoint i32 %21, 1
  %80 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %79) #10
  %81 = trunc i32 %80 to i16
  %82 = bitcast i16 %81 to half
  %83 = fpext half %82 to float
  %84 = tail call spir_func float @_Z3fmafff(float noundef %83, float noundef %73, float noundef %60) #11
  %85 = tail call spir_func float @_Z3fmafff(float noundef %83, float noundef %78, float noundef %61) #11
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %79) #10
  %87 = trunc i32 %86 to i16
  %88 = bitcast i16 %87 to half
  %89 = fpext half %88 to float
  %90 = tail call spir_func float @_Z3fmafff(float noundef %89, float noundef %73, float noundef %67) #11
  %91 = tail call spir_func float @_Z3fmafff(float noundef %89, float noundef %78, float noundef %68) #11
  %92 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %69) #10
  %93 = lshr i32 %92, 16
  %94 = trunc nuw i32 %93 to i16
  %95 = bitcast i16 %94 to half
  %96 = fpext half %95 to float
  %97 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %74) #10
  %98 = lshr i32 %97, 16
  %99 = trunc nuw i32 %98 to i16
  %100 = bitcast i16 %99 to half
  %101 = fpext half %100 to float
  %102 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %79) #10
  %103 = lshr i32 %102, 16
  %104 = trunc nuw i32 %103 to i16
  %105 = bitcast i16 %104 to half
  %106 = fpext half %105 to float
  %107 = tail call spir_func float @_Z3fmafff(float noundef %106, float noundef %96, float noundef %84) #11
  %108 = tail call spir_func float @_Z3fmafff(float noundef %106, float noundef %101, float noundef %85) #11
  %109 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %79) #10
  %110 = lshr i32 %109, 16
  %111 = trunc nuw i32 %110 to i16
  %112 = bitcast i16 %111 to half
  %113 = fpext half %112 to float
  %114 = tail call spir_func float @_Z3fmafff(float noundef %113, float noundef %96, float noundef %90) #11
  %115 = tail call spir_func float @_Z3fmafff(float noundef %113, float noundef %101, float noundef %91) #11
  %116 = or disjoint i32 %23, 2
  %117 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %116) #10
  %118 = trunc i32 %117 to i16
  %119 = bitcast i16 %118 to half
  %120 = fpext half %119 to float
  %121 = or disjoint i32 %23, 6
  %122 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %121) #10
  %123 = trunc i32 %122 to i16
  %124 = bitcast i16 %123 to half
  %125 = fpext half %124 to float
  %126 = or disjoint i32 %21, 2
  %127 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %126) #10
  %128 = trunc i32 %127 to i16
  %129 = bitcast i16 %128 to half
  %130 = fpext half %129 to float
  %131 = tail call spir_func float @_Z3fmafff(float noundef %130, float noundef %120, float noundef %107) #11
  %132 = tail call spir_func float @_Z3fmafff(float noundef %130, float noundef %125, float noundef %108) #11
  %133 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %126) #10
  %134 = trunc i32 %133 to i16
  %135 = bitcast i16 %134 to half
  %136 = fpext half %135 to float
  %137 = tail call spir_func float @_Z3fmafff(float noundef %136, float noundef %120, float noundef %114) #11
  %138 = tail call spir_func float @_Z3fmafff(float noundef %136, float noundef %125, float noundef %115) #11
  %139 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %116) #10
  %140 = lshr i32 %139, 16
  %141 = trunc nuw i32 %140 to i16
  %142 = bitcast i16 %141 to half
  %143 = fpext half %142 to float
  %144 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %121) #10
  %145 = lshr i32 %144, 16
  %146 = trunc nuw i32 %145 to i16
  %147 = bitcast i16 %146 to half
  %148 = fpext half %147 to float
  %149 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %126) #10
  %150 = lshr i32 %149, 16
  %151 = trunc nuw i32 %150 to i16
  %152 = bitcast i16 %151 to half
  %153 = fpext half %152 to float
  %154 = tail call spir_func float @_Z3fmafff(float noundef %153, float noundef %143, float noundef %131) #11
  %155 = tail call spir_func float @_Z3fmafff(float noundef %153, float noundef %148, float noundef %132) #11
  %156 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %126) #10
  %157 = lshr i32 %156, 16
  %158 = trunc nuw i32 %157 to i16
  %159 = bitcast i16 %158 to half
  %160 = fpext half %159 to float
  %161 = tail call spir_func float @_Z3fmafff(float noundef %160, float noundef %143, float noundef %137) #11
  %162 = tail call spir_func float @_Z3fmafff(float noundef %160, float noundef %148, float noundef %138) #11
  %163 = or disjoint i32 %23, 3
  %164 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %163) #10
  %165 = trunc i32 %164 to i16
  %166 = bitcast i16 %165 to half
  %167 = fpext half %166 to float
  %168 = or disjoint i32 %23, 7
  %169 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %168) #10
  %170 = trunc i32 %169 to i16
  %171 = bitcast i16 %170 to half
  %172 = fpext half %171 to float
  %173 = or i32 %20, 3
  %174 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %173) #10
  %175 = trunc i32 %174 to i16
  %176 = bitcast i16 %175 to half
  %177 = fpext half %176 to float
  %178 = tail call spir_func float @_Z3fmafff(float noundef %177, float noundef %167, float noundef %154) #11
  %179 = tail call spir_func float @_Z3fmafff(float noundef %177, float noundef %172, float noundef %155) #11
  %180 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %173) #10
  %181 = trunc i32 %180 to i16
  %182 = bitcast i16 %181 to half
  %183 = fpext half %182 to float
  %184 = tail call spir_func float @_Z3fmafff(float noundef %183, float noundef %167, float noundef %161) #11
  %185 = tail call spir_func float @_Z3fmafff(float noundef %183, float noundef %172, float noundef %162) #11
  %186 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %163) #10
  %187 = lshr i32 %186, 16
  %188 = trunc nuw i32 %187 to i16
  %189 = bitcast i16 %188 to half
  %190 = fpext half %189 to float
  %191 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %168) #10
  %192 = lshr i32 %191, 16
  %193 = trunc nuw i32 %192 to i16
  %194 = bitcast i16 %193 to half
  %195 = fpext half %194 to float
  %196 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %173) #10
  %197 = lshr i32 %196, 16
  %198 = trunc nuw i32 %197 to i16
  %199 = bitcast i16 %198 to half
  %200 = fpext half %199 to float
  %201 = tail call spir_func float @_Z3fmafff(float noundef %200, float noundef %190, float noundef %178) #11
  %202 = tail call spir_func float @_Z3fmafff(float noundef %200, float noundef %195, float noundef %179) #11
  %203 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %173) #10
  %204 = lshr i32 %203, 16
  %205 = trunc nuw i32 %204 to i16
  %206 = bitcast i16 %205 to half
  %207 = fpext half %206 to float
  %208 = tail call spir_func float @_Z3fmafff(float noundef %207, float noundef %190, float noundef %184) #11
  %209 = tail call spir_func float @_Z3fmafff(float noundef %207, float noundef %195, float noundef %185) #11
  %210 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %23) #10
  %211 = trunc i32 %210 to i16
  %212 = bitcast i16 %211 to half
  %213 = fpext half %212 to float
  %214 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %28) #10
  %215 = trunc i32 %214 to i16
  %216 = bitcast i16 %215 to half
  %217 = fpext half %216 to float
  %218 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %21) #10
  %219 = trunc i32 %218 to i16
  %220 = bitcast i16 %219 to half
  %221 = fpext half %220 to float
  %222 = tail call spir_func float @_Z3fmafff(float noundef %221, float noundef %213, float noundef %201) #11
  %223 = tail call spir_func float @_Z3fmafff(float noundef %221, float noundef %217, float noundef %202) #11
  %224 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %21) #10
  %225 = trunc i32 %224 to i16
  %226 = bitcast i16 %225 to half
  %227 = fpext half %226 to float
  %228 = tail call spir_func float @_Z3fmafff(float noundef %227, float noundef %213, float noundef %208) #11
  %229 = tail call spir_func float @_Z3fmafff(float noundef %227, float noundef %217, float noundef %209) #11
  %230 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %23) #10
  %231 = lshr i32 %230, 16
  %232 = trunc nuw i32 %231 to i16
  %233 = bitcast i16 %232 to half
  %234 = fpext half %233 to float
  %235 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %28) #10
  %236 = lshr i32 %235, 16
  %237 = trunc nuw i32 %236 to i16
  %238 = bitcast i16 %237 to half
  %239 = fpext half %238 to float
  %240 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %21) #10
  %241 = lshr i32 %240, 16
  %242 = trunc nuw i32 %241 to i16
  %243 = bitcast i16 %242 to half
  %244 = fpext half %243 to float
  %245 = tail call spir_func float @_Z3fmafff(float noundef %244, float noundef %234, float noundef %222) #11
  %246 = tail call spir_func float @_Z3fmafff(float noundef %244, float noundef %239, float noundef %223) #11
  %247 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %21) #10
  %248 = lshr i32 %247, 16
  %249 = trunc nuw i32 %248 to i16
  %250 = bitcast i16 %249 to half
  %251 = fpext half %250 to float
  %252 = tail call spir_func float @_Z3fmafff(float noundef %251, float noundef %234, float noundef %228) #11
  %253 = tail call spir_func float @_Z3fmafff(float noundef %251, float noundef %239, float noundef %229) #11
  %254 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %69) #10
  %255 = trunc i32 %254 to i16
  %256 = bitcast i16 %255 to half
  %257 = fpext half %256 to float
  %258 = or disjoint i32 %23, 5
  %259 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %258) #10
  %260 = trunc i32 %259 to i16
  %261 = bitcast i16 %260 to half
  %262 = fpext half %261 to float
  %263 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %79) #10
  %264 = trunc i32 %263 to i16
  %265 = bitcast i16 %264 to half
  %266 = fpext half %265 to float
  %267 = tail call spir_func float @_Z3fmafff(float noundef %266, float noundef %257, float noundef %245) #11
  %268 = tail call spir_func float @_Z3fmafff(float noundef %266, float noundef %262, float noundef %246) #11
  %269 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %79) #10
  %270 = trunc i32 %269 to i16
  %271 = bitcast i16 %270 to half
  %272 = fpext half %271 to float
  %273 = tail call spir_func float @_Z3fmafff(float noundef %272, float noundef %257, float noundef %252) #11
  %274 = tail call spir_func float @_Z3fmafff(float noundef %272, float noundef %262, float noundef %253) #11
  %275 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %69) #10
  %276 = lshr i32 %275, 16
  %277 = trunc nuw i32 %276 to i16
  %278 = bitcast i16 %277 to half
  %279 = fpext half %278 to float
  %280 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %258) #10
  %281 = lshr i32 %280, 16
  %282 = trunc nuw i32 %281 to i16
  %283 = bitcast i16 %282 to half
  %284 = fpext half %283 to float
  %285 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %79) #10
  %286 = lshr i32 %285, 16
  %287 = trunc nuw i32 %286 to i16
  %288 = bitcast i16 %287 to half
  %289 = fpext half %288 to float
  %290 = tail call spir_func float @_Z3fmafff(float noundef %289, float noundef %279, float noundef %267) #11
  %291 = tail call spir_func float @_Z3fmafff(float noundef %289, float noundef %284, float noundef %268) #11
  %292 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %79) #10
  %293 = lshr i32 %292, 16
  %294 = trunc nuw i32 %293 to i16
  %295 = bitcast i16 %294 to half
  %296 = fpext half %295 to float
  %297 = tail call spir_func float @_Z3fmafff(float noundef %296, float noundef %279, float noundef %273) #11
  %298 = tail call spir_func float @_Z3fmafff(float noundef %296, float noundef %284, float noundef %274) #11
  %299 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %116) #10
  %300 = trunc i32 %299 to i16
  %301 = bitcast i16 %300 to half
  %302 = fpext half %301 to float
  %303 = or disjoint i32 %23, 6
  %304 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %303) #10
  %305 = trunc i32 %304 to i16
  %306 = bitcast i16 %305 to half
  %307 = fpext half %306 to float
  %308 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %126) #10
  %309 = trunc i32 %308 to i16
  %310 = bitcast i16 %309 to half
  %311 = fpext half %310 to float
  %312 = tail call spir_func float @_Z3fmafff(float noundef %311, float noundef %302, float noundef %290) #11
  %313 = tail call spir_func float @_Z3fmafff(float noundef %311, float noundef %307, float noundef %291) #11
  %314 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %126) #10
  %315 = trunc i32 %314 to i16
  %316 = bitcast i16 %315 to half
  %317 = fpext half %316 to float
  %318 = tail call spir_func float @_Z3fmafff(float noundef %317, float noundef %302, float noundef %297) #11
  %319 = tail call spir_func float @_Z3fmafff(float noundef %317, float noundef %307, float noundef %298) #11
  %320 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %116) #10
  %321 = lshr i32 %320, 16
  %322 = trunc nuw i32 %321 to i16
  %323 = bitcast i16 %322 to half
  %324 = fpext half %323 to float
  %325 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %303) #10
  %326 = lshr i32 %325, 16
  %327 = trunc nuw i32 %326 to i16
  %328 = bitcast i16 %327 to half
  %329 = fpext half %328 to float
  %330 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %126) #10
  %331 = lshr i32 %330, 16
  %332 = trunc nuw i32 %331 to i16
  %333 = bitcast i16 %332 to half
  %334 = fpext half %333 to float
  %335 = tail call spir_func float @_Z3fmafff(float noundef %334, float noundef %324, float noundef %312) #11
  %336 = tail call spir_func float @_Z3fmafff(float noundef %334, float noundef %329, float noundef %313) #11
  %337 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %126) #10
  %338 = lshr i32 %337, 16
  %339 = trunc nuw i32 %338 to i16
  %340 = bitcast i16 %339 to half
  %341 = fpext half %340 to float
  %342 = tail call spir_func float @_Z3fmafff(float noundef %341, float noundef %324, float noundef %318) #11
  %343 = tail call spir_func float @_Z3fmafff(float noundef %341, float noundef %329, float noundef %319) #11
  %344 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %163) #10
  %345 = trunc i32 %344 to i16
  %346 = bitcast i16 %345 to half
  %347 = fpext half %346 to float
  %348 = or disjoint i32 %23, 7
  %349 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %348) #10
  %350 = trunc i32 %349 to i16
  %351 = bitcast i16 %350 to half
  %352 = fpext half %351 to float
  %353 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %173) #10
  %354 = trunc i32 %353 to i16
  %355 = bitcast i16 %354 to half
  %356 = fpext half %355 to float
  %357 = tail call spir_func float @_Z3fmafff(float noundef %356, float noundef %347, float noundef %335) #11
  %358 = tail call spir_func float @_Z3fmafff(float noundef %356, float noundef %352, float noundef %336) #11
  %359 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %173) #10
  %360 = trunc i32 %359 to i16
  %361 = bitcast i16 %360 to half
  %362 = fpext half %361 to float
  %363 = tail call spir_func float @_Z3fmafff(float noundef %362, float noundef %347, float noundef %342) #11
  %364 = tail call spir_func float @_Z3fmafff(float noundef %362, float noundef %352, float noundef %343) #11
  %365 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %163) #10
  %366 = lshr i32 %365, 16
  %367 = trunc nuw i32 %366 to i16
  %368 = bitcast i16 %367 to half
  %369 = fpext half %368 to float
  %370 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %348) #10
  %371 = lshr i32 %370, 16
  %372 = trunc nuw i32 %371 to i16
  %373 = bitcast i16 %372 to half
  %374 = fpext half %373 to float
  %375 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %173) #10
  %376 = lshr i32 %375, 16
  %377 = trunc nuw i32 %376 to i16
  %378 = bitcast i16 %377 to half
  %379 = fpext half %378 to float
  %380 = tail call spir_func float @_Z3fmafff(float noundef %379, float noundef %369, float noundef %357) #11
  %381 = tail call spir_func float @_Z3fmafff(float noundef %379, float noundef %374, float noundef %358) #11
  %382 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %173) #10
  %383 = lshr i32 %382, 16
  %384 = trunc nuw i32 %383 to i16
  %385 = bitcast i16 %384 to half
  %386 = fpext half %385 to float
  %387 = tail call spir_func float @_Z3fmafff(float noundef %386, float noundef %369, float noundef %363) #11
  %388 = tail call spir_func float @_Z3fmafff(float noundef %386, float noundef %374, float noundef %364) #11
  %389 = tail call spir_func half @_Z12convert_halff(float noundef %380) #11
  %390 = insertelement <2 x half> poison, half %389, i64 0
  %391 = tail call spir_func half @_Z12convert_halff(float noundef %381) #11
  %392 = insertelement <2 x half> %390, half %391, i64 1
  %393 = bitcast <2 x half> %392 to i32
  %394 = insertelement <2 x i32> poison, i32 %393, i64 0
  %395 = tail call spir_func half @_Z12convert_halff(float noundef %387) #11
  %396 = insertelement <2 x half> poison, half %395, i64 0
  %397 = tail call spir_func half @_Z12convert_halff(float noundef %388) #11
  %398 = insertelement <2 x half> %396, half %397, i64 1
  %399 = bitcast <2 x half> %398 to i32
  %400 = insertelement <2 x i32> %394, i32 %399, i64 1
  ret <2 x i32> %400
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x float> @__zlift_mma_m16n8k8_f32_tf32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, <4 x float> noundef %6) local_unnamed_addr #0 {
  %8 = extractelement <4 x float> %6, i64 0
  %9 = extractelement <4 x float> %6, i64 1
  %10 = extractelement <4 x float> %6, i64 2
  %11 = extractelement <4 x float> %6, i64 3
  %12 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %13 = and i32 %12, -4
  %14 = shl i32 %12, 3
  %15 = and i32 %14, 24
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %15) #10
  %17 = bitcast i32 %16 to float
  %18 = or disjoint i32 %15, 4
  %19 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %18) #10
  %20 = bitcast i32 %19 to float
  %21 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %13) #10
  %22 = bitcast i32 %21 to float
  %23 = tail call spir_func float @_Z3fmafff(float noundef %22, float noundef %17, float noundef %8) #11
  %24 = tail call spir_func float @_Z3fmafff(float noundef %22, float noundef %20, float noundef %9) #11
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %13) #10
  %26 = bitcast i32 %25 to float
  %27 = tail call spir_func float @_Z3fmafff(float noundef %26, float noundef %17, float noundef %10) #11
  %28 = tail call spir_func float @_Z3fmafff(float noundef %26, float noundef %20, float noundef %11) #11
  %29 = or disjoint i32 %15, 1
  %30 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %29) #10
  %31 = bitcast i32 %30 to float
  %32 = or disjoint i32 %15, 5
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %32) #10
  %34 = bitcast i32 %33 to float
  %35 = or disjoint i32 %13, 1
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %35) #10
  %37 = bitcast i32 %36 to float
  %38 = tail call spir_func float @_Z3fmafff(float noundef %37, float noundef %31, float noundef %23) #11
  %39 = tail call spir_func float @_Z3fmafff(float noundef %37, float noundef %34, float noundef %24) #11
  %40 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %35) #10
  %41 = bitcast i32 %40 to float
  %42 = tail call spir_func float @_Z3fmafff(float noundef %41, float noundef %31, float noundef %27) #11
  %43 = tail call spir_func float @_Z3fmafff(float noundef %41, float noundef %34, float noundef %28) #11
  %44 = or disjoint i32 %15, 2
  %45 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %44) #10
  %46 = bitcast i32 %45 to float
  %47 = or disjoint i32 %15, 6
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %47) #10
  %49 = bitcast i32 %48 to float
  %50 = or disjoint i32 %13, 2
  %51 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %50) #10
  %52 = bitcast i32 %51 to float
  %53 = tail call spir_func float @_Z3fmafff(float noundef %52, float noundef %46, float noundef %38) #11
  %54 = tail call spir_func float @_Z3fmafff(float noundef %52, float noundef %49, float noundef %39) #11
  %55 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %50) #10
  %56 = bitcast i32 %55 to float
  %57 = tail call spir_func float @_Z3fmafff(float noundef %56, float noundef %46, float noundef %42) #11
  %58 = tail call spir_func float @_Z3fmafff(float noundef %56, float noundef %49, float noundef %43) #11
  %59 = or disjoint i32 %15, 3
  %60 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %59) #10
  %61 = bitcast i32 %60 to float
  %62 = or disjoint i32 %15, 7
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %62) #10
  %64 = bitcast i32 %63 to float
  %65 = or i32 %12, 3
  %66 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %65) #10
  %67 = bitcast i32 %66 to float
  %68 = tail call spir_func float @_Z3fmafff(float noundef %67, float noundef %61, float noundef %53) #11
  %69 = tail call spir_func float @_Z3fmafff(float noundef %67, float noundef %64, float noundef %54) #11
  %70 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %65) #10
  %71 = bitcast i32 %70 to float
  %72 = tail call spir_func float @_Z3fmafff(float noundef %71, float noundef %61, float noundef %57) #11
  %73 = tail call spir_func float @_Z3fmafff(float noundef %71, float noundef %64, float noundef %58) #11
  %74 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %15) #10
  %75 = bitcast i32 %74 to float
  %76 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %18) #10
  %77 = bitcast i32 %76 to float
  %78 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %13) #10
  %79 = bitcast i32 %78 to float
  %80 = tail call spir_func float @_Z3fmafff(float noundef %79, float noundef %75, float noundef %68) #11
  %81 = tail call spir_func float @_Z3fmafff(float noundef %79, float noundef %77, float noundef %69) #11
  %82 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %13) #10
  %83 = bitcast i32 %82 to float
  %84 = tail call spir_func float @_Z3fmafff(float noundef %83, float noundef %75, float noundef %72) #11
  %85 = tail call spir_func float @_Z3fmafff(float noundef %83, float noundef %77, float noundef %73) #11
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %29) #10
  %87 = bitcast i32 %86 to float
  %88 = or disjoint i32 %15, 5
  %89 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %88) #10
  %90 = bitcast i32 %89 to float
  %91 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %35) #10
  %92 = bitcast i32 %91 to float
  %93 = tail call spir_func float @_Z3fmafff(float noundef %92, float noundef %87, float noundef %80) #11
  %94 = tail call spir_func float @_Z3fmafff(float noundef %92, float noundef %90, float noundef %81) #11
  %95 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %35) #10
  %96 = bitcast i32 %95 to float
  %97 = tail call spir_func float @_Z3fmafff(float noundef %96, float noundef %87, float noundef %84) #11
  %98 = tail call spir_func float @_Z3fmafff(float noundef %96, float noundef %90, float noundef %85) #11
  %99 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %44) #10
  %100 = bitcast i32 %99 to float
  %101 = or disjoint i32 %15, 6
  %102 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %101) #10
  %103 = bitcast i32 %102 to float
  %104 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %50) #10
  %105 = bitcast i32 %104 to float
  %106 = tail call spir_func float @_Z3fmafff(float noundef %105, float noundef %100, float noundef %93) #11
  %107 = tail call spir_func float @_Z3fmafff(float noundef %105, float noundef %103, float noundef %94) #11
  %108 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %50) #10
  %109 = bitcast i32 %108 to float
  %110 = tail call spir_func float @_Z3fmafff(float noundef %109, float noundef %100, float noundef %97) #11
  %111 = tail call spir_func float @_Z3fmafff(float noundef %109, float noundef %103, float noundef %98) #11
  %112 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %59) #10
  %113 = bitcast i32 %112 to float
  %114 = or disjoint i32 %15, 7
  %115 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %114) #10
  %116 = bitcast i32 %115 to float
  %117 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %65) #10
  %118 = bitcast i32 %117 to float
  %119 = tail call spir_func float @_Z3fmafff(float noundef %118, float noundef %113, float noundef %106) #11
  %120 = tail call spir_func float @_Z3fmafff(float noundef %118, float noundef %116, float noundef %107) #11
  %121 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %65) #10
  %122 = bitcast i32 %121 to float
  %123 = tail call spir_func float @_Z3fmafff(float noundef %122, float noundef %113, float noundef %110) #11
  %124 = tail call spir_func float @_Z3fmafff(float noundef %122, float noundef %116, float noundef %111) #11
  %125 = insertelement <4 x float> poison, float %119, i64 0
  %126 = insertelement <4 x float> %125, float %120, i64 1
  %127 = insertelement <4 x float> %126, float %123, i64 2
  %128 = insertelement <4 x float> %127, float %124, i64 3
  ret <4 x float> %128
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x double> @__zlift_mma_m8n8k4_f64(double noundef %0, double noundef %1, <2 x double> noundef %2) local_unnamed_addr #0 {
  %4 = extractelement <2 x double> %2, i64 0
  %5 = extractelement <2 x double> %2, i64 1
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = and i32 %6, -4
  %8 = shl i32 %6, 3
  %9 = and i32 %8, 24
  %10 = bitcast double %1 to <2 x i32>
  %11 = extractelement <2 x i32> %10, i64 0
  %12 = extractelement <2 x i32> %10, i64 1
  %13 = bitcast double %0 to <2 x i32>
  %14 = extractelement <2 x i32> %13, i64 0
  %15 = extractelement <2 x i32> %13, i64 1
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %9) #10
  %17 = insertelement <2 x i32> poison, i32 %16, i64 0
  %18 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %9) #10
  %19 = insertelement <2 x i32> %17, i32 %18, i64 1
  %20 = bitcast <2 x i32> %19 to double
  %21 = or disjoint i32 %9, 4
  %22 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %21) #10
  %23 = insertelement <2 x i32> poison, i32 %22, i64 0
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %21) #10
  %25 = insertelement <2 x i32> %23, i32 %24, i64 1
  %26 = bitcast <2 x i32> %25 to double
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %14, i32 noundef %7) #10
  %28 = insertelement <2 x i32> poison, i32 %27, i64 0
  %29 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %15, i32 noundef %7) #10
  %30 = insertelement <2 x i32> %28, i32 %29, i64 1
  %31 = bitcast <2 x i32> %30 to double
  %32 = tail call spir_func double @_Z3fmaddd(double noundef %31, double noundef %20, double noundef %4) #11
  %33 = tail call spir_func double @_Z3fmaddd(double noundef %31, double noundef %26, double noundef %5) #11
  %34 = or disjoint i32 %9, 1
  %35 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %34) #10
  %36 = insertelement <2 x i32> poison, i32 %35, i64 0
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %34) #10
  %38 = insertelement <2 x i32> %36, i32 %37, i64 1
  %39 = bitcast <2 x i32> %38 to double
  %40 = or disjoint i32 %9, 5
  %41 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %40) #10
  %42 = insertelement <2 x i32> poison, i32 %41, i64 0
  %43 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %40) #10
  %44 = insertelement <2 x i32> %42, i32 %43, i64 1
  %45 = bitcast <2 x i32> %44 to double
  %46 = or disjoint i32 %7, 1
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %14, i32 noundef %46) #10
  %48 = insertelement <2 x i32> poison, i32 %47, i64 0
  %49 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %15, i32 noundef %46) #10
  %50 = insertelement <2 x i32> %48, i32 %49, i64 1
  %51 = bitcast <2 x i32> %50 to double
  %52 = tail call spir_func double @_Z3fmaddd(double noundef %51, double noundef %39, double noundef %32) #11
  %53 = tail call spir_func double @_Z3fmaddd(double noundef %51, double noundef %45, double noundef %33) #11
  %54 = or disjoint i32 %9, 2
  %55 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %54) #10
  %56 = insertelement <2 x i32> poison, i32 %55, i64 0
  %57 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %54) #10
  %58 = insertelement <2 x i32> %56, i32 %57, i64 1
  %59 = bitcast <2 x i32> %58 to double
  %60 = or disjoint i32 %9, 6
  %61 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %60) #10
  %62 = insertelement <2 x i32> poison, i32 %61, i64 0
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %60) #10
  %64 = insertelement <2 x i32> %62, i32 %63, i64 1
  %65 = bitcast <2 x i32> %64 to double
  %66 = or disjoint i32 %7, 2
  %67 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %14, i32 noundef %66) #10
  %68 = insertelement <2 x i32> poison, i32 %67, i64 0
  %69 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %15, i32 noundef %66) #10
  %70 = insertelement <2 x i32> %68, i32 %69, i64 1
  %71 = bitcast <2 x i32> %70 to double
  %72 = tail call spir_func double @_Z3fmaddd(double noundef %71, double noundef %59, double noundef %52) #11
  %73 = tail call spir_func double @_Z3fmaddd(double noundef %71, double noundef %65, double noundef %53) #11
  %74 = or disjoint i32 %9, 3
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %74) #10
  %76 = insertelement <2 x i32> poison, i32 %75, i64 0
  %77 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %74) #10
  %78 = insertelement <2 x i32> %76, i32 %77, i64 1
  %79 = bitcast <2 x i32> %78 to double
  %80 = or disjoint i32 %9, 7
  %81 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %80) #10
  %82 = insertelement <2 x i32> poison, i32 %81, i64 0
  %83 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %12, i32 noundef %80) #10
  %84 = insertelement <2 x i32> %82, i32 %83, i64 1
  %85 = bitcast <2 x i32> %84 to double
  %86 = or i32 %6, 3
  %87 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %14, i32 noundef %86) #10
  %88 = insertelement <2 x i32> poison, i32 %87, i64 0
  %89 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %15, i32 noundef %86) #10
  %90 = insertelement <2 x i32> %88, i32 %89, i64 1
  %91 = bitcast <2 x i32> %90 to double
  %92 = tail call spir_func double @_Z3fmaddd(double noundef %91, double noundef %79, double noundef %72) #11
  %93 = tail call spir_func double @_Z3fmaddd(double noundef %91, double noundef %85, double noundef %73) #11
  %94 = insertelement <2 x double> poison, double %92, i64 0
  %95 = insertelement <2 x double> %94, double %93, i64 1
  ret <2 x double> %95
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func double @_Z3fmaddd(double noundef, double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x double> @__zlift_mma_m16n8k16_f64(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5, double noundef %6, double noundef %7, double noundef %8, double noundef %9, double noundef %10, double noundef %11, <4 x double> noundef %12) local_unnamed_addr #0 {
  %14 = extractelement <4 x double> %12, i64 0
  %15 = extractelement <4 x double> %12, i64 1
  %16 = extractelement <4 x double> %12, i64 2
  %17 = extractelement <4 x double> %12, i64 3
  %18 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %19 = and i32 %18, -4
  %20 = shl i32 %18, 3
  %21 = and i32 %20, 24
  %22 = bitcast double %8 to <2 x i32>
  %23 = extractelement <2 x i32> %22, i64 0
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %21) #10
  %25 = insertelement <2 x i32> poison, i32 %24, i64 0
  %26 = extractelement <2 x i32> %22, i64 1
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %21) #10
  %28 = insertelement <2 x i32> %25, i32 %27, i64 1
  %29 = bitcast <2 x i32> %28 to double
  %30 = or disjoint i32 %21, 4
  %31 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %30) #10
  %32 = insertelement <2 x i32> poison, i32 %31, i64 0
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %30) #10
  %34 = insertelement <2 x i32> %32, i32 %33, i64 1
  %35 = bitcast <2 x i32> %34 to double
  %36 = bitcast double %0 to <2 x i32>
  %37 = extractelement <2 x i32> %36, i64 0
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %37, i32 noundef %19) #10
  %39 = insertelement <2 x i32> poison, i32 %38, i64 0
  %40 = extractelement <2 x i32> %36, i64 1
  %41 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %40, i32 noundef %19) #10
  %42 = insertelement <2 x i32> %39, i32 %41, i64 1
  %43 = bitcast <2 x i32> %42 to double
  %44 = tail call spir_func double @_Z3fmaddd(double noundef %43, double noundef %29, double noundef %14) #11
  %45 = tail call spir_func double @_Z3fmaddd(double noundef %43, double noundef %35, double noundef %15) #11
  %46 = bitcast double %1 to <2 x i32>
  %47 = extractelement <2 x i32> %46, i64 0
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %47, i32 noundef %19) #10
  %49 = insertelement <2 x i32> poison, i32 %48, i64 0
  %50 = extractelement <2 x i32> %46, i64 1
  %51 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %50, i32 noundef %19) #10
  %52 = insertelement <2 x i32> %49, i32 %51, i64 1
  %53 = bitcast <2 x i32> %52 to double
  %54 = tail call spir_func double @_Z3fmaddd(double noundef %53, double noundef %29, double noundef %16) #11
  %55 = tail call spir_func double @_Z3fmaddd(double noundef %53, double noundef %35, double noundef %17) #11
  %56 = or disjoint i32 %21, 1
  %57 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %56) #10
  %58 = insertelement <2 x i32> poison, i32 %57, i64 0
  %59 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %56) #10
  %60 = insertelement <2 x i32> %58, i32 %59, i64 1
  %61 = bitcast <2 x i32> %60 to double
  %62 = or disjoint i32 %21, 5
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %62) #10
  %64 = insertelement <2 x i32> poison, i32 %63, i64 0
  %65 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %62) #10
  %66 = insertelement <2 x i32> %64, i32 %65, i64 1
  %67 = bitcast <2 x i32> %66 to double
  %68 = or disjoint i32 %19, 1
  %69 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %37, i32 noundef %68) #10
  %70 = insertelement <2 x i32> poison, i32 %69, i64 0
  %71 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %40, i32 noundef %68) #10
  %72 = insertelement <2 x i32> %70, i32 %71, i64 1
  %73 = bitcast <2 x i32> %72 to double
  %74 = tail call spir_func double @_Z3fmaddd(double noundef %73, double noundef %61, double noundef %44) #11
  %75 = tail call spir_func double @_Z3fmaddd(double noundef %73, double noundef %67, double noundef %45) #11
  %76 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %47, i32 noundef %68) #10
  %77 = insertelement <2 x i32> poison, i32 %76, i64 0
  %78 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %50, i32 noundef %68) #10
  %79 = insertelement <2 x i32> %77, i32 %78, i64 1
  %80 = bitcast <2 x i32> %79 to double
  %81 = tail call spir_func double @_Z3fmaddd(double noundef %80, double noundef %61, double noundef %54) #11
  %82 = tail call spir_func double @_Z3fmaddd(double noundef %80, double noundef %67, double noundef %55) #11
  %83 = or disjoint i32 %21, 2
  %84 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %83) #10
  %85 = insertelement <2 x i32> poison, i32 %84, i64 0
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %83) #10
  %87 = insertelement <2 x i32> %85, i32 %86, i64 1
  %88 = bitcast <2 x i32> %87 to double
  %89 = or disjoint i32 %21, 6
  %90 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %89) #10
  %91 = insertelement <2 x i32> poison, i32 %90, i64 0
  %92 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %89) #10
  %93 = insertelement <2 x i32> %91, i32 %92, i64 1
  %94 = bitcast <2 x i32> %93 to double
  %95 = or disjoint i32 %19, 2
  %96 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %37, i32 noundef %95) #10
  %97 = insertelement <2 x i32> poison, i32 %96, i64 0
  %98 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %40, i32 noundef %95) #10
  %99 = insertelement <2 x i32> %97, i32 %98, i64 1
  %100 = bitcast <2 x i32> %99 to double
  %101 = tail call spir_func double @_Z3fmaddd(double noundef %100, double noundef %88, double noundef %74) #11
  %102 = tail call spir_func double @_Z3fmaddd(double noundef %100, double noundef %94, double noundef %75) #11
  %103 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %47, i32 noundef %95) #10
  %104 = insertelement <2 x i32> poison, i32 %103, i64 0
  %105 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %50, i32 noundef %95) #10
  %106 = insertelement <2 x i32> %104, i32 %105, i64 1
  %107 = bitcast <2 x i32> %106 to double
  %108 = tail call spir_func double @_Z3fmaddd(double noundef %107, double noundef %88, double noundef %81) #11
  %109 = tail call spir_func double @_Z3fmaddd(double noundef %107, double noundef %94, double noundef %82) #11
  %110 = or disjoint i32 %21, 3
  %111 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %110) #10
  %112 = insertelement <2 x i32> poison, i32 %111, i64 0
  %113 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %110) #10
  %114 = insertelement <2 x i32> %112, i32 %113, i64 1
  %115 = bitcast <2 x i32> %114 to double
  %116 = or disjoint i32 %21, 7
  %117 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %23, i32 noundef %116) #10
  %118 = insertelement <2 x i32> poison, i32 %117, i64 0
  %119 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %26, i32 noundef %116) #10
  %120 = insertelement <2 x i32> %118, i32 %119, i64 1
  %121 = bitcast <2 x i32> %120 to double
  %122 = or i32 %18, 3
  %123 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %37, i32 noundef %122) #10
  %124 = insertelement <2 x i32> poison, i32 %123, i64 0
  %125 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %40, i32 noundef %122) #10
  %126 = insertelement <2 x i32> %124, i32 %125, i64 1
  %127 = bitcast <2 x i32> %126 to double
  %128 = tail call spir_func double @_Z3fmaddd(double noundef %127, double noundef %115, double noundef %101) #11
  %129 = tail call spir_func double @_Z3fmaddd(double noundef %127, double noundef %121, double noundef %102) #11
  %130 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %47, i32 noundef %122) #10
  %131 = insertelement <2 x i32> poison, i32 %130, i64 0
  %132 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %50, i32 noundef %122) #10
  %133 = insertelement <2 x i32> %131, i32 %132, i64 1
  %134 = bitcast <2 x i32> %133 to double
  %135 = tail call spir_func double @_Z3fmaddd(double noundef %134, double noundef %115, double noundef %108) #11
  %136 = tail call spir_func double @_Z3fmaddd(double noundef %134, double noundef %121, double noundef %109) #11
  %137 = bitcast double %9 to <2 x i32>
  %138 = extractelement <2 x i32> %137, i64 0
  %139 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %21) #10
  %140 = insertelement <2 x i32> poison, i32 %139, i64 0
  %141 = extractelement <2 x i32> %137, i64 1
  %142 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %21) #10
  %143 = insertelement <2 x i32> %140, i32 %142, i64 1
  %144 = bitcast <2 x i32> %143 to double
  %145 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %30) #10
  %146 = insertelement <2 x i32> poison, i32 %145, i64 0
  %147 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %30) #10
  %148 = insertelement <2 x i32> %146, i32 %147, i64 1
  %149 = bitcast <2 x i32> %148 to double
  %150 = bitcast double %2 to <2 x i32>
  %151 = extractelement <2 x i32> %150, i64 0
  %152 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %151, i32 noundef %19) #10
  %153 = insertelement <2 x i32> poison, i32 %152, i64 0
  %154 = extractelement <2 x i32> %150, i64 1
  %155 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %154, i32 noundef %19) #10
  %156 = insertelement <2 x i32> %153, i32 %155, i64 1
  %157 = bitcast <2 x i32> %156 to double
  %158 = tail call spir_func double @_Z3fmaddd(double noundef %157, double noundef %144, double noundef %128) #11
  %159 = tail call spir_func double @_Z3fmaddd(double noundef %157, double noundef %149, double noundef %129) #11
  %160 = bitcast double %3 to <2 x i32>
  %161 = extractelement <2 x i32> %160, i64 0
  %162 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %161, i32 noundef %19) #10
  %163 = insertelement <2 x i32> poison, i32 %162, i64 0
  %164 = extractelement <2 x i32> %160, i64 1
  %165 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %164, i32 noundef %19) #10
  %166 = insertelement <2 x i32> %163, i32 %165, i64 1
  %167 = bitcast <2 x i32> %166 to double
  %168 = tail call spir_func double @_Z3fmaddd(double noundef %167, double noundef %144, double noundef %135) #11
  %169 = tail call spir_func double @_Z3fmaddd(double noundef %167, double noundef %149, double noundef %136) #11
  %170 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %56) #10
  %171 = insertelement <2 x i32> poison, i32 %170, i64 0
  %172 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %56) #10
  %173 = insertelement <2 x i32> %171, i32 %172, i64 1
  %174 = bitcast <2 x i32> %173 to double
  %175 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %62) #10
  %176 = insertelement <2 x i32> poison, i32 %175, i64 0
  %177 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %62) #10
  %178 = insertelement <2 x i32> %176, i32 %177, i64 1
  %179 = bitcast <2 x i32> %178 to double
  %180 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %151, i32 noundef %68) #10
  %181 = insertelement <2 x i32> poison, i32 %180, i64 0
  %182 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %154, i32 noundef %68) #10
  %183 = insertelement <2 x i32> %181, i32 %182, i64 1
  %184 = bitcast <2 x i32> %183 to double
  %185 = tail call spir_func double @_Z3fmaddd(double noundef %184, double noundef %174, double noundef %158) #11
  %186 = tail call spir_func double @_Z3fmaddd(double noundef %184, double noundef %179, double noundef %159) #11
  %187 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %161, i32 noundef %68) #10
  %188 = insertelement <2 x i32> poison, i32 %187, i64 0
  %189 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %164, i32 noundef %68) #10
  %190 = insertelement <2 x i32> %188, i32 %189, i64 1
  %191 = bitcast <2 x i32> %190 to double
  %192 = tail call spir_func double @_Z3fmaddd(double noundef %191, double noundef %174, double noundef %168) #11
  %193 = tail call spir_func double @_Z3fmaddd(double noundef %191, double noundef %179, double noundef %169) #11
  %194 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %83) #10
  %195 = insertelement <2 x i32> poison, i32 %194, i64 0
  %196 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %83) #10
  %197 = insertelement <2 x i32> %195, i32 %196, i64 1
  %198 = bitcast <2 x i32> %197 to double
  %199 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %89) #10
  %200 = insertelement <2 x i32> poison, i32 %199, i64 0
  %201 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %89) #10
  %202 = insertelement <2 x i32> %200, i32 %201, i64 1
  %203 = bitcast <2 x i32> %202 to double
  %204 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %151, i32 noundef %95) #10
  %205 = insertelement <2 x i32> poison, i32 %204, i64 0
  %206 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %154, i32 noundef %95) #10
  %207 = insertelement <2 x i32> %205, i32 %206, i64 1
  %208 = bitcast <2 x i32> %207 to double
  %209 = tail call spir_func double @_Z3fmaddd(double noundef %208, double noundef %198, double noundef %185) #11
  %210 = tail call spir_func double @_Z3fmaddd(double noundef %208, double noundef %203, double noundef %186) #11
  %211 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %161, i32 noundef %95) #10
  %212 = insertelement <2 x i32> poison, i32 %211, i64 0
  %213 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %164, i32 noundef %95) #10
  %214 = insertelement <2 x i32> %212, i32 %213, i64 1
  %215 = bitcast <2 x i32> %214 to double
  %216 = tail call spir_func double @_Z3fmaddd(double noundef %215, double noundef %198, double noundef %192) #11
  %217 = tail call spir_func double @_Z3fmaddd(double noundef %215, double noundef %203, double noundef %193) #11
  %218 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %110) #10
  %219 = insertelement <2 x i32> poison, i32 %218, i64 0
  %220 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %110) #10
  %221 = insertelement <2 x i32> %219, i32 %220, i64 1
  %222 = bitcast <2 x i32> %221 to double
  %223 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %138, i32 noundef %116) #10
  %224 = insertelement <2 x i32> poison, i32 %223, i64 0
  %225 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %141, i32 noundef %116) #10
  %226 = insertelement <2 x i32> %224, i32 %225, i64 1
  %227 = bitcast <2 x i32> %226 to double
  %228 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %151, i32 noundef %122) #10
  %229 = insertelement <2 x i32> poison, i32 %228, i64 0
  %230 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %154, i32 noundef %122) #10
  %231 = insertelement <2 x i32> %229, i32 %230, i64 1
  %232 = bitcast <2 x i32> %231 to double
  %233 = tail call spir_func double @_Z3fmaddd(double noundef %232, double noundef %222, double noundef %209) #11
  %234 = tail call spir_func double @_Z3fmaddd(double noundef %232, double noundef %227, double noundef %210) #11
  %235 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %161, i32 noundef %122) #10
  %236 = insertelement <2 x i32> poison, i32 %235, i64 0
  %237 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %164, i32 noundef %122) #10
  %238 = insertelement <2 x i32> %236, i32 %237, i64 1
  %239 = bitcast <2 x i32> %238 to double
  %240 = tail call spir_func double @_Z3fmaddd(double noundef %239, double noundef %222, double noundef %216) #11
  %241 = tail call spir_func double @_Z3fmaddd(double noundef %239, double noundef %227, double noundef %217) #11
  %242 = bitcast double %10 to <2 x i32>
  %243 = extractelement <2 x i32> %242, i64 0
  %244 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %21) #10
  %245 = insertelement <2 x i32> poison, i32 %244, i64 0
  %246 = extractelement <2 x i32> %242, i64 1
  %247 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %21) #10
  %248 = insertelement <2 x i32> %245, i32 %247, i64 1
  %249 = bitcast <2 x i32> %248 to double
  %250 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %30) #10
  %251 = insertelement <2 x i32> poison, i32 %250, i64 0
  %252 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %30) #10
  %253 = insertelement <2 x i32> %251, i32 %252, i64 1
  %254 = bitcast <2 x i32> %253 to double
  %255 = bitcast double %4 to <2 x i32>
  %256 = extractelement <2 x i32> %255, i64 0
  %257 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %256, i32 noundef %19) #10
  %258 = insertelement <2 x i32> poison, i32 %257, i64 0
  %259 = extractelement <2 x i32> %255, i64 1
  %260 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %259, i32 noundef %19) #10
  %261 = insertelement <2 x i32> %258, i32 %260, i64 1
  %262 = bitcast <2 x i32> %261 to double
  %263 = tail call spir_func double @_Z3fmaddd(double noundef %262, double noundef %249, double noundef %233) #11
  %264 = tail call spir_func double @_Z3fmaddd(double noundef %262, double noundef %254, double noundef %234) #11
  %265 = bitcast double %5 to <2 x i32>
  %266 = extractelement <2 x i32> %265, i64 0
  %267 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %266, i32 noundef %19) #10
  %268 = insertelement <2 x i32> poison, i32 %267, i64 0
  %269 = extractelement <2 x i32> %265, i64 1
  %270 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %269, i32 noundef %19) #10
  %271 = insertelement <2 x i32> %268, i32 %270, i64 1
  %272 = bitcast <2 x i32> %271 to double
  %273 = tail call spir_func double @_Z3fmaddd(double noundef %272, double noundef %249, double noundef %240) #11
  %274 = tail call spir_func double @_Z3fmaddd(double noundef %272, double noundef %254, double noundef %241) #11
  %275 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %56) #10
  %276 = insertelement <2 x i32> poison, i32 %275, i64 0
  %277 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %56) #10
  %278 = insertelement <2 x i32> %276, i32 %277, i64 1
  %279 = bitcast <2 x i32> %278 to double
  %280 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %62) #10
  %281 = insertelement <2 x i32> poison, i32 %280, i64 0
  %282 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %62) #10
  %283 = insertelement <2 x i32> %281, i32 %282, i64 1
  %284 = bitcast <2 x i32> %283 to double
  %285 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %256, i32 noundef %68) #10
  %286 = insertelement <2 x i32> poison, i32 %285, i64 0
  %287 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %259, i32 noundef %68) #10
  %288 = insertelement <2 x i32> %286, i32 %287, i64 1
  %289 = bitcast <2 x i32> %288 to double
  %290 = tail call spir_func double @_Z3fmaddd(double noundef %289, double noundef %279, double noundef %263) #11
  %291 = tail call spir_func double @_Z3fmaddd(double noundef %289, double noundef %284, double noundef %264) #11
  %292 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %266, i32 noundef %68) #10
  %293 = insertelement <2 x i32> poison, i32 %292, i64 0
  %294 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %269, i32 noundef %68) #10
  %295 = insertelement <2 x i32> %293, i32 %294, i64 1
  %296 = bitcast <2 x i32> %295 to double
  %297 = tail call spir_func double @_Z3fmaddd(double noundef %296, double noundef %279, double noundef %273) #11
  %298 = tail call spir_func double @_Z3fmaddd(double noundef %296, double noundef %284, double noundef %274) #11
  %299 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %83) #10
  %300 = insertelement <2 x i32> poison, i32 %299, i64 0
  %301 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %83) #10
  %302 = insertelement <2 x i32> %300, i32 %301, i64 1
  %303 = bitcast <2 x i32> %302 to double
  %304 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %89) #10
  %305 = insertelement <2 x i32> poison, i32 %304, i64 0
  %306 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %89) #10
  %307 = insertelement <2 x i32> %305, i32 %306, i64 1
  %308 = bitcast <2 x i32> %307 to double
  %309 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %256, i32 noundef %95) #10
  %310 = insertelement <2 x i32> poison, i32 %309, i64 0
  %311 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %259, i32 noundef %95) #10
  %312 = insertelement <2 x i32> %310, i32 %311, i64 1
  %313 = bitcast <2 x i32> %312 to double
  %314 = tail call spir_func double @_Z3fmaddd(double noundef %313, double noundef %303, double noundef %290) #11
  %315 = tail call spir_func double @_Z3fmaddd(double noundef %313, double noundef %308, double noundef %291) #11
  %316 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %266, i32 noundef %95) #10
  %317 = insertelement <2 x i32> poison, i32 %316, i64 0
  %318 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %269, i32 noundef %95) #10
  %319 = insertelement <2 x i32> %317, i32 %318, i64 1
  %320 = bitcast <2 x i32> %319 to double
  %321 = tail call spir_func double @_Z3fmaddd(double noundef %320, double noundef %303, double noundef %297) #11
  %322 = tail call spir_func double @_Z3fmaddd(double noundef %320, double noundef %308, double noundef %298) #11
  %323 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %110) #10
  %324 = insertelement <2 x i32> poison, i32 %323, i64 0
  %325 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %110) #10
  %326 = insertelement <2 x i32> %324, i32 %325, i64 1
  %327 = bitcast <2 x i32> %326 to double
  %328 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %243, i32 noundef %116) #10
  %329 = insertelement <2 x i32> poison, i32 %328, i64 0
  %330 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %246, i32 noundef %116) #10
  %331 = insertelement <2 x i32> %329, i32 %330, i64 1
  %332 = bitcast <2 x i32> %331 to double
  %333 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %256, i32 noundef %122) #10
  %334 = insertelement <2 x i32> poison, i32 %333, i64 0
  %335 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %259, i32 noundef %122) #10
  %336 = insertelement <2 x i32> %334, i32 %335, i64 1
  %337 = bitcast <2 x i32> %336 to double
  %338 = tail call spir_func double @_Z3fmaddd(double noundef %337, double noundef %327, double noundef %314) #11
  %339 = tail call spir_func double @_Z3fmaddd(double noundef %337, double noundef %332, double noundef %315) #11
  %340 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %266, i32 noundef %122) #10
  %341 = insertelement <2 x i32> poison, i32 %340, i64 0
  %342 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %269, i32 noundef %122) #10
  %343 = insertelement <2 x i32> %341, i32 %342, i64 1
  %344 = bitcast <2 x i32> %343 to double
  %345 = tail call spir_func double @_Z3fmaddd(double noundef %344, double noundef %327, double noundef %321) #11
  %346 = tail call spir_func double @_Z3fmaddd(double noundef %344, double noundef %332, double noundef %322) #11
  %347 = bitcast double %11 to <2 x i32>
  %348 = extractelement <2 x i32> %347, i64 0
  %349 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %21) #10
  %350 = insertelement <2 x i32> poison, i32 %349, i64 0
  %351 = extractelement <2 x i32> %347, i64 1
  %352 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %21) #10
  %353 = insertelement <2 x i32> %350, i32 %352, i64 1
  %354 = bitcast <2 x i32> %353 to double
  %355 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %30) #10
  %356 = insertelement <2 x i32> poison, i32 %355, i64 0
  %357 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %30) #10
  %358 = insertelement <2 x i32> %356, i32 %357, i64 1
  %359 = bitcast <2 x i32> %358 to double
  %360 = bitcast double %6 to <2 x i32>
  %361 = extractelement <2 x i32> %360, i64 0
  %362 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %361, i32 noundef %19) #10
  %363 = insertelement <2 x i32> poison, i32 %362, i64 0
  %364 = extractelement <2 x i32> %360, i64 1
  %365 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %364, i32 noundef %19) #10
  %366 = insertelement <2 x i32> %363, i32 %365, i64 1
  %367 = bitcast <2 x i32> %366 to double
  %368 = tail call spir_func double @_Z3fmaddd(double noundef %367, double noundef %354, double noundef %338) #11
  %369 = tail call spir_func double @_Z3fmaddd(double noundef %367, double noundef %359, double noundef %339) #11
  %370 = bitcast double %7 to <2 x i32>
  %371 = extractelement <2 x i32> %370, i64 0
  %372 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %371, i32 noundef %19) #10
  %373 = insertelement <2 x i32> poison, i32 %372, i64 0
  %374 = extractelement <2 x i32> %370, i64 1
  %375 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %374, i32 noundef %19) #10
  %376 = insertelement <2 x i32> %373, i32 %375, i64 1
  %377 = bitcast <2 x i32> %376 to double
  %378 = tail call spir_func double @_Z3fmaddd(double noundef %377, double noundef %354, double noundef %345) #11
  %379 = tail call spir_func double @_Z3fmaddd(double noundef %377, double noundef %359, double noundef %346) #11
  %380 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %56) #10
  %381 = insertelement <2 x i32> poison, i32 %380, i64 0
  %382 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %56) #10
  %383 = insertelement <2 x i32> %381, i32 %382, i64 1
  %384 = bitcast <2 x i32> %383 to double
  %385 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %62) #10
  %386 = insertelement <2 x i32> poison, i32 %385, i64 0
  %387 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %62) #10
  %388 = insertelement <2 x i32> %386, i32 %387, i64 1
  %389 = bitcast <2 x i32> %388 to double
  %390 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %361, i32 noundef %68) #10
  %391 = insertelement <2 x i32> poison, i32 %390, i64 0
  %392 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %364, i32 noundef %68) #10
  %393 = insertelement <2 x i32> %391, i32 %392, i64 1
  %394 = bitcast <2 x i32> %393 to double
  %395 = tail call spir_func double @_Z3fmaddd(double noundef %394, double noundef %384, double noundef %368) #11
  %396 = tail call spir_func double @_Z3fmaddd(double noundef %394, double noundef %389, double noundef %369) #11
  %397 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %371, i32 noundef %68) #10
  %398 = insertelement <2 x i32> poison, i32 %397, i64 0
  %399 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %374, i32 noundef %68) #10
  %400 = insertelement <2 x i32> %398, i32 %399, i64 1
  %401 = bitcast <2 x i32> %400 to double
  %402 = tail call spir_func double @_Z3fmaddd(double noundef %401, double noundef %384, double noundef %378) #11
  %403 = tail call spir_func double @_Z3fmaddd(double noundef %401, double noundef %389, double noundef %379) #11
  %404 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %83) #10
  %405 = insertelement <2 x i32> poison, i32 %404, i64 0
  %406 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %83) #10
  %407 = insertelement <2 x i32> %405, i32 %406, i64 1
  %408 = bitcast <2 x i32> %407 to double
  %409 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %89) #10
  %410 = insertelement <2 x i32> poison, i32 %409, i64 0
  %411 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %89) #10
  %412 = insertelement <2 x i32> %410, i32 %411, i64 1
  %413 = bitcast <2 x i32> %412 to double
  %414 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %361, i32 noundef %95) #10
  %415 = insertelement <2 x i32> poison, i32 %414, i64 0
  %416 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %364, i32 noundef %95) #10
  %417 = insertelement <2 x i32> %415, i32 %416, i64 1
  %418 = bitcast <2 x i32> %417 to double
  %419 = tail call spir_func double @_Z3fmaddd(double noundef %418, double noundef %408, double noundef %395) #11
  %420 = tail call spir_func double @_Z3fmaddd(double noundef %418, double noundef %413, double noundef %396) #11
  %421 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %371, i32 noundef %95) #10
  %422 = insertelement <2 x i32> poison, i32 %421, i64 0
  %423 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %374, i32 noundef %95) #10
  %424 = insertelement <2 x i32> %422, i32 %423, i64 1
  %425 = bitcast <2 x i32> %424 to double
  %426 = tail call spir_func double @_Z3fmaddd(double noundef %425, double noundef %408, double noundef %402) #11
  %427 = tail call spir_func double @_Z3fmaddd(double noundef %425, double noundef %413, double noundef %403) #11
  %428 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %110) #10
  %429 = insertelement <2 x i32> poison, i32 %428, i64 0
  %430 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %110) #10
  %431 = insertelement <2 x i32> %429, i32 %430, i64 1
  %432 = bitcast <2 x i32> %431 to double
  %433 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %348, i32 noundef %116) #10
  %434 = insertelement <2 x i32> poison, i32 %433, i64 0
  %435 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %351, i32 noundef %116) #10
  %436 = insertelement <2 x i32> %434, i32 %435, i64 1
  %437 = bitcast <2 x i32> %436 to double
  %438 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %361, i32 noundef %122) #10
  %439 = insertelement <2 x i32> poison, i32 %438, i64 0
  %440 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %364, i32 noundef %122) #10
  %441 = insertelement <2 x i32> %439, i32 %440, i64 1
  %442 = bitcast <2 x i32> %441 to double
  %443 = tail call spir_func double @_Z3fmaddd(double noundef %442, double noundef %432, double noundef %419) #11
  %444 = tail call spir_func double @_Z3fmaddd(double noundef %442, double noundef %437, double noundef %420) #11
  %445 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %371, i32 noundef %122) #10
  %446 = insertelement <2 x i32> poison, i32 %445, i64 0
  %447 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %374, i32 noundef %122) #10
  %448 = insertelement <2 x i32> %446, i32 %447, i64 1
  %449 = bitcast <2 x i32> %448 to double
  %450 = tail call spir_func double @_Z3fmaddd(double noundef %449, double noundef %432, double noundef %426) #11
  %451 = tail call spir_func double @_Z3fmaddd(double noundef %449, double noundef %437, double noundef %427) #11
  %452 = insertelement <4 x double> poison, double %443, i64 0
  %453 = insertelement <4 x double> %452, double %444, i64 1
  %454 = insertelement <4 x double> %453, double %450, i64 2
  %455 = insertelement <4 x double> %454, double %451, i64 3
  ret <4 x double> %455
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zlift_mma_m8n8k16_s32_s8(i32 noundef %0, i32 noundef %1, <2 x i32> noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = and i32 %4, -4
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 24
  %8 = or disjoint i32 %7, 4
  %9 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %10 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %8) #10
  %11 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %5) #10
  %12 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %13 = insertelement <2 x i32> poison, i32 %9, i64 0
  %14 = insertelement <2 x i32> %13, i32 %12, i64 1
  %15 = shl <2 x i32> %14, <i32 24, i32 16>
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %8) #10
  %17 = insertelement <2 x i32> poison, i32 %10, i64 0
  %18 = insertelement <2 x i32> %17, i32 %16, i64 1
  %19 = shl <2 x i32> %18, <i32 24, i32 16>
  %20 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %5) #10
  %21 = insertelement <2 x i32> poison, i32 %11, i64 0
  %22 = insertelement <2 x i32> %21, i32 %20, i64 1
  %23 = shl <2 x i32> %22, <i32 24, i32 16>
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %25 = shl i32 %24, 8
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %8) #10
  %27 = shl i32 %26, 8
  %28 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %5) #10
  %29 = shl i32 %28, 8
  %30 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %31 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %8) #10
  %32 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %5) #10
  %33 = or disjoint i32 %7, 1
  %34 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %33) #10
  %35 = shl i32 %34, 24
  %36 = or disjoint i32 %7, 5
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %36) #10
  %38 = shl i32 %37, 24
  %39 = or disjoint i32 %5, 1
  %40 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %39) #10
  %41 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %33) #10
  %42 = shl i32 %41, 16
  %43 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %36) #10
  %44 = shl i32 %43, 16
  %45 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %39) #10
  %46 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %33) #10
  %47 = shl i32 %46, 8
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %36) #10
  %49 = shl i32 %48, 8
  %50 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %39) #10
  %51 = shl i32 %50, 8
  %52 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %33) #10
  %53 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %36) #10
  %54 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %39) #10
  %55 = or disjoint i32 %7, 2
  %56 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %55) #10
  %57 = or disjoint i32 %7, 6
  %58 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %57) #10
  %59 = shl i32 %58, 24
  %60 = or disjoint i32 %5, 2
  %61 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %60) #10
  %62 = shl i32 %61, 24
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %55) #10
  %64 = insertelement <2 x i32> poison, i32 %56, i64 0
  %65 = insertelement <2 x i32> %64, i32 %63, i64 1
  %66 = shl <2 x i32> %65, <i32 24, i32 16>
  %67 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %57) #10
  %68 = shl i32 %67, 16
  %69 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %60) #10
  %70 = shl i32 %69, 16
  %71 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %55) #10
  %72 = shl i32 %71, 8
  %73 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %57) #10
  %74 = shl i32 %73, 8
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %60) #10
  %76 = shl i32 %75, 8
  %77 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %55) #10
  %78 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %57) #10
  %79 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %60) #10
  %80 = or disjoint i32 %7, 3
  %81 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %80) #10
  %82 = or disjoint i32 %7, 7
  %83 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %82) #10
  %84 = shl i32 %83, 24
  %85 = or i32 %4, 3
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %85) #10
  %87 = shl i32 %86, 24
  %88 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %80) #10
  %89 = shl i32 %88, 16
  %90 = ashr i32 %89, 24
  %91 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %82) #10
  %92 = shl i32 %91, 16
  %93 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %85) #10
  %94 = shl i32 %93, 16
  %95 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %80) #10
  %96 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %82) #10
  %97 = shl i32 %96, 8
  %98 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %85) #10
  %99 = shl i32 %98, 8
  %100 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %80) #10
  %101 = ashr i32 %100, 24
  %102 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %82) #10
  %103 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %85) #10
  %104 = shufflevector <2 x i32> %23, <2 x i32> poison, <16 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %105 = insertelement <16 x i32> %104, i32 %29, i64 2
  %106 = insertelement <16 x i32> %105, i32 %32, i64 3
  %107 = ashr i32 %51, 24
  %108 = ashr i32 %103, 24
  %109 = shufflevector <2 x i32> %19, <2 x i32> poison, <16 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %110 = insertelement <16 x i32> %109, i32 %27, i64 2
  %111 = insertelement <16 x i32> %110, i32 %31, i64 3
  %112 = insertelement <16 x i32> %111, i32 %38, i64 4
  %113 = insertelement <16 x i32> %112, i32 %44, i64 5
  %114 = insertelement <16 x i32> %113, i32 %49, i64 6
  %115 = insertelement <16 x i32> %114, i32 %53, i64 7
  %116 = insertelement <16 x i32> %115, i32 %59, i64 8
  %117 = insertelement <16 x i32> %116, i32 %68, i64 9
  %118 = insertelement <16 x i32> %117, i32 %74, i64 10
  %119 = insertelement <16 x i32> %118, i32 %78, i64 11
  %120 = insertelement <16 x i32> %119, i32 %84, i64 12
  %121 = insertelement <16 x i32> %120, i32 %92, i64 13
  %122 = insertelement <16 x i32> %121, i32 %97, i64 14
  %123 = insertelement <16 x i32> %122, i32 %103, i64 15
  %124 = ashr <16 x i32> %123, splat (i32 24)
  %125 = insertelement <2 x i32> poison, i32 %40, i64 0
  %126 = insertelement <2 x i32> %125, i32 %45, i64 1
  %127 = shl <2 x i32> %126, <i32 24, i32 16>
  %128 = shufflevector <2 x i32> %15, <2 x i32> poison, <8 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %129 = insertelement <8 x i32> %128, i32 %25, i64 2
  %130 = insertelement <8 x i32> %129, i32 %30, i64 3
  %131 = insertelement <8 x i32> %130, i32 %35, i64 4
  %132 = insertelement <8 x i32> %131, i32 %42, i64 5
  %133 = insertelement <8 x i32> %132, i32 %47, i64 6
  %134 = insertelement <8 x i32> %133, i32 %52, i64 7
  %135 = ashr <8 x i32> %134, splat (i32 24)
  %136 = shufflevector <2 x i32> %127, <2 x i32> poison, <16 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %137 = shufflevector <16 x i32> %106, <16 x i32> %136, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 16, i32 17, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %138 = insertelement <16 x i32> %137, i32 %51, i64 6
  %139 = insertelement <16 x i32> %138, i32 %54, i64 7
  %140 = insertelement <16 x i32> %139, i32 %62, i64 8
  %141 = insertelement <16 x i32> %140, i32 %70, i64 9
  %142 = insertelement <16 x i32> %141, i32 %76, i64 10
  %143 = insertelement <16 x i32> %142, i32 %79, i64 11
  %144 = insertelement <16 x i32> %143, i32 %87, i64 12
  %145 = insertelement <16 x i32> %144, i32 %94, i64 13
  %146 = insertelement <16 x i32> %145, i32 %99, i64 14
  %147 = insertelement <16 x i32> %146, i32 %102, i64 15
  %148 = ashr <16 x i32> %147, splat (i32 24)
  %149 = ashr <2 x i32> %127, splat (i32 24)
  %150 = shufflevector <2 x i32> %23, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 poison, i32 poison>
  %151 = insertelement <4 x i32> %150, i32 %29, i64 2
  %152 = insertelement <4 x i32> %151, i32 %32, i64 3
  %153 = ashr <4 x i32> %152, splat (i32 24)
  %154 = shufflevector <16 x i32> %148, <16 x i32> poison, <8 x i32> <i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 7>
  %155 = insertelement <8 x i32> %154, i32 %107, i64 6
  %156 = shufflevector <4 x i32> %153, <4 x i32> poison, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 poison, i32 poison, i32 poison, i32 poison>
  %157 = shufflevector <8 x i32> %156, <8 x i32> %155, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 poison, i32 poison, i32 14, i32 15>
  %158 = shufflevector <2 x i32> %149, <2 x i32> poison, <8 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %159 = shufflevector <8 x i32> %157, <8 x i32> %158, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 8, i32 9, i32 6, i32 7>
  %160 = mul nsw <8 x i32> %159, %135
  %161 = mul nsw <16 x i32> %124, %148
  %162 = shufflevector <2 x i32> %66, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 poison, i32 poison>
  %163 = insertelement <4 x i32> %162, i32 %72, i64 2
  %164 = insertelement <4 x i32> %163, i32 %77, i64 3
  %165 = ashr <4 x i32> %164, splat (i32 24)
  %166 = shufflevector <16 x i32> %148, <16 x i32> poison, <4 x i32> <i32 8, i32 9, i32 10, i32 11>
  %167 = mul nsw <4 x i32> %166, %165
  %168 = extractelement <16 x i32> %148, i64 13
  %169 = mul nsw i32 %168, %90
  %170 = tail call i32 @llvm.vector.reduce.add.v8i32(<8 x i32> %160)
  %171 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %167)
  %172 = add i32 %170, %171
  %173 = insertelement <2 x i32> poison, i32 %81, i64 0
  %174 = insertelement <2 x i32> %173, i32 %95, i64 1
  %175 = shl <2 x i32> %174, <i32 24, i32 8>
  %176 = ashr <2 x i32> %175, splat (i32 24)
  %177 = shufflevector <16 x i32> %148, <16 x i32> poison, <2 x i32> <i32 12, i32 14>
  %178 = mul nsw <2 x i32> %177, %176
  %179 = insertelement <2 x i32> poison, i32 %172, i64 0
  %180 = insertelement <2 x i32> %179, i32 %169, i64 1
  %181 = add <2 x i32> %180, %178
  %182 = shufflevector <2 x i32> %181, <2 x i32> poison, <2 x i32> <i32 1, i32 poison>
  %183 = add <2 x i32> %181, %182
  %184 = add <2 x i32> %183, %2
  %185 = mul nsw i32 %108, %101
  %186 = tail call i32 @llvm.vector.reduce.add.v16i32(<16 x i32> %161)
  %187 = insertelement <2 x i32> poison, i32 %185, i64 0
  %188 = insertelement <2 x i32> %187, i32 %186, i64 1
  %189 = shufflevector <2 x i32> %184, <2 x i32> %2, <2 x i32> <i32 0, i32 3>
  %190 = add <2 x i32> %188, %189
  ret <2 x i32> %190
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v8i32(<8 x i32>) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v16i32(<16 x i32>) #4

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x i32> @__zlift_mma_m16n8k32_s32_s8(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, <4 x i32> noundef %6) local_unnamed_addr #0 {
  %8 = shufflevector <4 x i32> %6, <4 x i32> poison, <4 x i32> <i32 1, i32 3, i32 0, i32 2>
  %9 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %10 = and i32 %9, -4
  %11 = shl i32 %9, 3
  %12 = and i32 %11, 24
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %12) #10
  %14 = or disjoint i32 %12, 4
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %14) #10
  %16 = insertelement <2 x i32> poison, i32 %15, i64 0
  %17 = insertelement <2 x i32> %16, i32 %13, i64 1
  %18 = shl <2 x i32> %17, splat (i32 24)
  %19 = ashr exact <2 x i32> %18, splat (i32 24)
  %20 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %21 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %22 = insertelement <2 x i32> poison, i32 %20, i64 0
  %23 = insertelement <2 x i32> %22, i32 %21, i64 1
  %24 = shl <2 x i32> %23, splat (i32 24)
  %25 = ashr exact <2 x i32> %24, splat (i32 24)
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %12) #10
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %14) #10
  %28 = insertelement <2 x i32> poison, i32 %27, i64 0
  %29 = insertelement <2 x i32> %28, i32 %26, i64 1
  %30 = shl <2 x i32> %29, splat (i32 16)
  %31 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %32 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %33 = insertelement <2 x i32> poison, i32 %31, i64 0
  %34 = insertelement <2 x i32> %33, i32 %32, i64 1
  %35 = shl <2 x i32> %34, splat (i32 16)
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %12) #10
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %14) #10
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %39 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %40 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %12) #10
  %41 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %14) #10
  %42 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %10) #10
  %43 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %44 = or disjoint i32 %12, 1
  %45 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %44) #10
  %46 = or disjoint i32 %12, 5
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %46) #10
  %48 = or disjoint i32 %10, 1
  %49 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %48) #10
  %50 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %48) #10
  %51 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %44) #10
  %52 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %46) #10
  %53 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %48) #10
  %54 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %48) #10
  %55 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %44) #10
  %56 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %46) #10
  %57 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %48) #10
  %58 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %48) #10
  %59 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %44) #10
  %60 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %46) #10
  %61 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %48) #10
  %62 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %48) #10
  %63 = or disjoint i32 %12, 2
  %64 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %63) #10
  %65 = or disjoint i32 %12, 6
  %66 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %65) #10
  %67 = or disjoint i32 %10, 2
  %68 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %67) #10
  %69 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %67) #10
  %70 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %63) #10
  %71 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %65) #10
  %72 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %67) #10
  %73 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %67) #10
  %74 = shufflevector <2 x i32> %25, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %75 = shufflevector <2 x i32> %19, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %76 = mul nsw <4 x i32> %74, %75
  %77 = add nsw <4 x i32> %8, %76
  %78 = ashr <2 x i32> %30, splat (i32 24)
  %79 = shufflevector <2 x i32> %78, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %80 = ashr <2 x i32> %35, splat (i32 24)
  %81 = shufflevector <2 x i32> %80, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %82 = mul nsw <4 x i32> %81, %79
  %83 = add nsw <4 x i32> %77, %82
  %84 = insertelement <2 x i32> poison, i32 %37, i64 0
  %85 = insertelement <2 x i32> %84, i32 %36, i64 1
  %86 = shl <2 x i32> %85, splat (i32 8)
  %87 = ashr <2 x i32> %86, splat (i32 24)
  %88 = shufflevector <2 x i32> %87, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %89 = insertelement <2 x i32> poison, i32 %38, i64 0
  %90 = insertelement <2 x i32> %89, i32 %39, i64 1
  %91 = shl <2 x i32> %90, splat (i32 8)
  %92 = ashr <2 x i32> %91, splat (i32 24)
  %93 = shufflevector <2 x i32> %92, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %94 = mul nsw <4 x i32> %93, %88
  %95 = add nsw <4 x i32> %83, %94
  %96 = insertelement <2 x i32> poison, i32 %41, i64 0
  %97 = insertelement <2 x i32> %96, i32 %40, i64 1
  %98 = ashr <2 x i32> %97, splat (i32 24)
  %99 = shufflevector <2 x i32> %98, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %100 = insertelement <2 x i32> poison, i32 %42, i64 0
  %101 = insertelement <2 x i32> %100, i32 %43, i64 1
  %102 = ashr <2 x i32> %101, splat (i32 24)
  %103 = shufflevector <2 x i32> %102, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %104 = mul nsw <4 x i32> %103, %99
  %105 = add nsw <4 x i32> %95, %104
  %106 = insertelement <2 x i32> poison, i32 %47, i64 0
  %107 = insertelement <2 x i32> %106, i32 %45, i64 1
  %108 = shl <2 x i32> %107, splat (i32 24)
  %109 = ashr exact <2 x i32> %108, splat (i32 24)
  %110 = shufflevector <2 x i32> %109, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %111 = insertelement <2 x i32> poison, i32 %49, i64 0
  %112 = insertelement <2 x i32> %111, i32 %50, i64 1
  %113 = shl <2 x i32> %112, splat (i32 24)
  %114 = ashr exact <2 x i32> %113, splat (i32 24)
  %115 = shufflevector <2 x i32> %114, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %116 = mul nsw <4 x i32> %115, %110
  %117 = add nsw <4 x i32> %105, %116
  %118 = insertelement <2 x i32> poison, i32 %52, i64 0
  %119 = insertelement <2 x i32> %118, i32 %51, i64 1
  %120 = shl <2 x i32> %119, splat (i32 16)
  %121 = ashr <2 x i32> %120, splat (i32 24)
  %122 = shufflevector <2 x i32> %121, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %123 = insertelement <2 x i32> poison, i32 %53, i64 0
  %124 = insertelement <2 x i32> %123, i32 %54, i64 1
  %125 = shl <2 x i32> %124, splat (i32 16)
  %126 = ashr <2 x i32> %125, splat (i32 24)
  %127 = shufflevector <2 x i32> %126, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %128 = mul nsw <4 x i32> %127, %122
  %129 = add nsw <4 x i32> %117, %128
  %130 = insertelement <2 x i32> poison, i32 %56, i64 0
  %131 = insertelement <2 x i32> %130, i32 %55, i64 1
  %132 = shl <2 x i32> %131, splat (i32 8)
  %133 = ashr <2 x i32> %132, splat (i32 24)
  %134 = shufflevector <2 x i32> %133, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %135 = insertelement <2 x i32> poison, i32 %57, i64 0
  %136 = insertelement <2 x i32> %135, i32 %58, i64 1
  %137 = shl <2 x i32> %136, splat (i32 8)
  %138 = ashr <2 x i32> %137, splat (i32 24)
  %139 = shufflevector <2 x i32> %138, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %140 = mul nsw <4 x i32> %139, %134
  %141 = add nsw <4 x i32> %129, %140
  %142 = insertelement <2 x i32> poison, i32 %60, i64 0
  %143 = insertelement <2 x i32> %142, i32 %59, i64 1
  %144 = ashr <2 x i32> %143, splat (i32 24)
  %145 = shufflevector <2 x i32> %144, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %146 = insertelement <2 x i32> poison, i32 %61, i64 0
  %147 = insertelement <2 x i32> %146, i32 %62, i64 1
  %148 = ashr <2 x i32> %147, splat (i32 24)
  %149 = shufflevector <2 x i32> %148, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %150 = mul nsw <4 x i32> %149, %145
  %151 = add nsw <4 x i32> %141, %150
  %152 = insertelement <2 x i32> poison, i32 %66, i64 0
  %153 = insertelement <2 x i32> %152, i32 %64, i64 1
  %154 = shl <2 x i32> %153, splat (i32 24)
  %155 = ashr exact <2 x i32> %154, splat (i32 24)
  %156 = shufflevector <2 x i32> %155, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %157 = insertelement <2 x i32> poison, i32 %68, i64 0
  %158 = insertelement <2 x i32> %157, i32 %69, i64 1
  %159 = shl <2 x i32> %158, splat (i32 24)
  %160 = ashr exact <2 x i32> %159, splat (i32 24)
  %161 = shufflevector <2 x i32> %160, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %162 = mul nsw <4 x i32> %161, %156
  %163 = add nsw <4 x i32> %151, %162
  %164 = insertelement <2 x i32> poison, i32 %71, i64 0
  %165 = insertelement <2 x i32> %164, i32 %70, i64 1
  %166 = shl <2 x i32> %165, splat (i32 16)
  %167 = ashr <2 x i32> %166, splat (i32 24)
  %168 = shufflevector <2 x i32> %167, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %169 = insertelement <2 x i32> poison, i32 %72, i64 0
  %170 = insertelement <2 x i32> %169, i32 %73, i64 1
  %171 = shl <2 x i32> %170, splat (i32 16)
  %172 = ashr <2 x i32> %171, splat (i32 24)
  %173 = shufflevector <2 x i32> %172, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %174 = mul nsw <4 x i32> %173, %168
  %175 = add nsw <4 x i32> %163, %174
  %176 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %63) #10
  %177 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %65) #10
  %178 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %67) #10
  %179 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %67) #10
  %180 = insertelement <2 x i32> poison, i32 %177, i64 0
  %181 = insertelement <2 x i32> %180, i32 %176, i64 1
  %182 = shl <2 x i32> %181, splat (i32 8)
  %183 = ashr <2 x i32> %182, splat (i32 24)
  %184 = shufflevector <2 x i32> %183, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %185 = insertelement <2 x i32> poison, i32 %178, i64 0
  %186 = insertelement <2 x i32> %185, i32 %179, i64 1
  %187 = shl <2 x i32> %186, splat (i32 8)
  %188 = ashr <2 x i32> %187, splat (i32 24)
  %189 = shufflevector <2 x i32> %188, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %190 = mul nsw <4 x i32> %189, %184
  %191 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %63) #10
  %192 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %65) #10
  %193 = insertelement <2 x i32> poison, i32 %192, i64 0
  %194 = insertelement <2 x i32> %193, i32 %191, i64 1
  %195 = ashr <2 x i32> %194, splat (i32 24)
  %196 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %67) #10
  %197 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %67) #10
  %198 = insertelement <2 x i32> poison, i32 %196, i64 0
  %199 = insertelement <2 x i32> %198, i32 %197, i64 1
  %200 = ashr <2 x i32> %199, splat (i32 24)
  %201 = or disjoint i32 %12, 3
  %202 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %201) #10
  %203 = or disjoint i32 %12, 7
  %204 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %203) #10
  %205 = insertelement <2 x i32> poison, i32 %204, i64 0
  %206 = insertelement <2 x i32> %205, i32 %202, i64 1
  %207 = shl <2 x i32> %206, splat (i32 24)
  %208 = or i32 %9, 3
  %209 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %208) #10
  %210 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %208) #10
  %211 = insertelement <2 x i32> poison, i32 %209, i64 0
  %212 = insertelement <2 x i32> %211, i32 %210, i64 1
  %213 = shl <2 x i32> %212, splat (i32 24)
  %214 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %201) #10
  %215 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %203) #10
  %216 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %208) #10
  %217 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %208) #10
  %218 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %201) #10
  %219 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %203) #10
  %220 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %208) #10
  %221 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %208) #10
  %222 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %201) #10
  %223 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %203) #10
  %224 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef %208) #10
  %225 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %208) #10
  %226 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %12) #10
  %227 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %14) #10
  %228 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %10) #10
  %229 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %10) #10
  %230 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %12) #10
  %231 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %14) #10
  %232 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %10) #10
  %233 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %10) #10
  %234 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %12) #10
  %235 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %14) #10
  %236 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %10) #10
  %237 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %10) #10
  %238 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %12) #10
  %239 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %14) #10
  %240 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %10) #10
  %241 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %10) #10
  %242 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %44) #10
  %243 = or disjoint i32 %12, 5
  %244 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %243) #10
  %245 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %48) #10
  %246 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %48) #10
  %247 = add nsw <4 x i32> %175, %190
  %248 = shufflevector <2 x i32> %200, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %249 = shufflevector <2 x i32> %195, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %250 = mul nsw <4 x i32> %248, %249
  %251 = add nsw <4 x i32> %247, %250
  %252 = ashr exact <2 x i32> %207, splat (i32 24)
  %253 = shufflevector <2 x i32> %252, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %254 = ashr exact <2 x i32> %213, splat (i32 24)
  %255 = shufflevector <2 x i32> %254, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %256 = mul nsw <4 x i32> %255, %253
  %257 = add nsw <4 x i32> %251, %256
  %258 = insertelement <2 x i32> poison, i32 %215, i64 0
  %259 = insertelement <2 x i32> %258, i32 %214, i64 1
  %260 = shl <2 x i32> %259, splat (i32 16)
  %261 = ashr <2 x i32> %260, splat (i32 24)
  %262 = shufflevector <2 x i32> %261, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %263 = insertelement <2 x i32> poison, i32 %216, i64 0
  %264 = insertelement <2 x i32> %263, i32 %217, i64 1
  %265 = shl <2 x i32> %264, splat (i32 16)
  %266 = ashr <2 x i32> %265, splat (i32 24)
  %267 = shufflevector <2 x i32> %266, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %268 = mul nsw <4 x i32> %267, %262
  %269 = add nsw <4 x i32> %257, %268
  %270 = insertelement <2 x i32> poison, i32 %219, i64 0
  %271 = insertelement <2 x i32> %270, i32 %218, i64 1
  %272 = shl <2 x i32> %271, splat (i32 8)
  %273 = ashr <2 x i32> %272, splat (i32 24)
  %274 = shufflevector <2 x i32> %273, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %275 = insertelement <2 x i32> poison, i32 %220, i64 0
  %276 = insertelement <2 x i32> %275, i32 %221, i64 1
  %277 = shl <2 x i32> %276, splat (i32 8)
  %278 = ashr <2 x i32> %277, splat (i32 24)
  %279 = shufflevector <2 x i32> %278, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %280 = mul nsw <4 x i32> %279, %274
  %281 = add nsw <4 x i32> %269, %280
  %282 = insertelement <2 x i32> poison, i32 %223, i64 0
  %283 = insertelement <2 x i32> %282, i32 %222, i64 1
  %284 = ashr <2 x i32> %283, splat (i32 24)
  %285 = shufflevector <2 x i32> %284, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %286 = insertelement <2 x i32> poison, i32 %224, i64 0
  %287 = insertelement <2 x i32> %286, i32 %225, i64 1
  %288 = ashr <2 x i32> %287, splat (i32 24)
  %289 = shufflevector <2 x i32> %288, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %290 = mul nsw <4 x i32> %289, %285
  %291 = add nsw <4 x i32> %281, %290
  %292 = insertelement <2 x i32> poison, i32 %227, i64 0
  %293 = insertelement <2 x i32> %292, i32 %226, i64 1
  %294 = shl <2 x i32> %293, splat (i32 24)
  %295 = ashr exact <2 x i32> %294, splat (i32 24)
  %296 = shufflevector <2 x i32> %295, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %297 = insertelement <2 x i32> poison, i32 %228, i64 0
  %298 = insertelement <2 x i32> %297, i32 %229, i64 1
  %299 = shl <2 x i32> %298, splat (i32 24)
  %300 = ashr exact <2 x i32> %299, splat (i32 24)
  %301 = shufflevector <2 x i32> %300, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %302 = mul nsw <4 x i32> %301, %296
  %303 = add nsw <4 x i32> %291, %302
  %304 = insertelement <2 x i32> poison, i32 %231, i64 0
  %305 = insertelement <2 x i32> %304, i32 %230, i64 1
  %306 = shl <2 x i32> %305, splat (i32 16)
  %307 = ashr <2 x i32> %306, splat (i32 24)
  %308 = shufflevector <2 x i32> %307, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %309 = insertelement <2 x i32> poison, i32 %232, i64 0
  %310 = insertelement <2 x i32> %309, i32 %233, i64 1
  %311 = shl <2 x i32> %310, splat (i32 16)
  %312 = ashr <2 x i32> %311, splat (i32 24)
  %313 = shufflevector <2 x i32> %312, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %314 = mul nsw <4 x i32> %313, %308
  %315 = add nsw <4 x i32> %303, %314
  %316 = insertelement <2 x i32> poison, i32 %235, i64 0
  %317 = insertelement <2 x i32> %316, i32 %234, i64 1
  %318 = shl <2 x i32> %317, splat (i32 8)
  %319 = ashr <2 x i32> %318, splat (i32 24)
  %320 = shufflevector <2 x i32> %319, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %321 = insertelement <2 x i32> poison, i32 %236, i64 0
  %322 = insertelement <2 x i32> %321, i32 %237, i64 1
  %323 = shl <2 x i32> %322, splat (i32 8)
  %324 = ashr <2 x i32> %323, splat (i32 24)
  %325 = shufflevector <2 x i32> %324, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %326 = mul nsw <4 x i32> %325, %320
  %327 = add nsw <4 x i32> %315, %326
  %328 = insertelement <2 x i32> poison, i32 %239, i64 0
  %329 = insertelement <2 x i32> %328, i32 %238, i64 1
  %330 = ashr <2 x i32> %329, splat (i32 24)
  %331 = shufflevector <2 x i32> %330, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %332 = insertelement <2 x i32> poison, i32 %240, i64 0
  %333 = insertelement <2 x i32> %332, i32 %241, i64 1
  %334 = ashr <2 x i32> %333, splat (i32 24)
  %335 = shufflevector <2 x i32> %334, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %336 = mul nsw <4 x i32> %335, %331
  %337 = add nsw <4 x i32> %327, %336
  %338 = insertelement <2 x i32> poison, i32 %244, i64 0
  %339 = insertelement <2 x i32> %338, i32 %242, i64 1
  %340 = shl <2 x i32> %339, splat (i32 24)
  %341 = ashr exact <2 x i32> %340, splat (i32 24)
  %342 = shufflevector <2 x i32> %341, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %343 = insertelement <2 x i32> poison, i32 %245, i64 0
  %344 = insertelement <2 x i32> %343, i32 %246, i64 1
  %345 = shl <2 x i32> %344, splat (i32 24)
  %346 = ashr exact <2 x i32> %345, splat (i32 24)
  %347 = shufflevector <2 x i32> %346, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %348 = mul nsw <4 x i32> %347, %342
  %349 = add nsw <4 x i32> %337, %348
  %350 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %44) #10
  %351 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %243) #10
  %352 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %48) #10
  %353 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %48) #10
  %354 = insertelement <2 x i32> poison, i32 %351, i64 0
  %355 = insertelement <2 x i32> %354, i32 %350, i64 1
  %356 = shl <2 x i32> %355, splat (i32 16)
  %357 = ashr <2 x i32> %356, splat (i32 24)
  %358 = shufflevector <2 x i32> %357, <2 x i32> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
  %359 = insertelement <2 x i32> poison, i32 %352, i64 0
  %360 = insertelement <2 x i32> %359, i32 %353, i64 1
  %361 = shl <2 x i32> %360, splat (i32 16)
  %362 = ashr <2 x i32> %361, splat (i32 24)
  %363 = shufflevector <2 x i32> %362, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %364 = mul nsw <4 x i32> %363, %358
  %365 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %44) #10
  %366 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %243) #10
  %367 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %48) #10
  %368 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %48) #10
  %369 = insertelement <4 x i32> poison, i32 %366, i64 0
  %370 = insertelement <4 x i32> %369, i32 %368, i64 1
  %371 = insertelement <4 x i32> %370, i32 %367, i64 2
  %372 = insertelement <4 x i32> %371, i32 %365, i64 3
  %373 = shl <4 x i32> %372, splat (i32 8)
  %374 = ashr <4 x i32> %373, splat (i32 24)
  %375 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %44) #10
  %376 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %243) #10
  %377 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %48) #10
  %378 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %48) #10
  %379 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %63) #10
  %380 = or disjoint i32 %12, 6
  %381 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %380) #10
  %382 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %67) #10
  %383 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %67) #10
  %384 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %63) #10
  %385 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %380) #10
  %386 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %67) #10
  %387 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %67) #10
  %388 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %63) #10
  %389 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %380) #10
  %390 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %67) #10
  %391 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %67) #10
  %392 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %63) #10
  %393 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %380) #10
  %394 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %67) #10
  %395 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %67) #10
  %396 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %201) #10
  %397 = or disjoint i32 %12, 7
  %398 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %397) #10
  %399 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %208) #10
  %400 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %208) #10
  %401 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %201) #10
  %402 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %397) #10
  %403 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %208) #10
  %404 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %208) #10
  %405 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %201) #10
  %406 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %397) #10
  %407 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %208) #10
  %408 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %208) #10
  %409 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %201) #10
  %410 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %397) #10
  %411 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %208) #10
  %412 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %208) #10
  %413 = add nsw <4 x i32> %364, %349
  %414 = shufflevector <4 x i32> %374, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %415 = mul nsw <4 x i32> %374, %414
  %416 = add nsw <4 x i32> %415, %413
  %417 = insertelement <4 x i32> poison, i32 %376, i64 0
  %418 = insertelement <4 x i32> %417, i32 %378, i64 1
  %419 = insertelement <4 x i32> %418, i32 %377, i64 2
  %420 = insertelement <4 x i32> %419, i32 %375, i64 3
  %421 = ashr <4 x i32> %420, splat (i32 24)
  %422 = shufflevector <4 x i32> %421, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %423 = mul nsw <4 x i32> %421, %422
  %424 = add nsw <4 x i32> %423, %416
  %425 = insertelement <4 x i32> poison, i32 %381, i64 0
  %426 = insertelement <4 x i32> %425, i32 %383, i64 1
  %427 = insertelement <4 x i32> %426, i32 %382, i64 2
  %428 = insertelement <4 x i32> %427, i32 %379, i64 3
  %429 = shl <4 x i32> %428, splat (i32 24)
  %430 = ashr exact <4 x i32> %429, splat (i32 24)
  %431 = shufflevector <4 x i32> %430, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %432 = mul nsw <4 x i32> %430, %431
  %433 = add nsw <4 x i32> %432, %424
  %434 = insertelement <4 x i32> poison, i32 %385, i64 0
  %435 = insertelement <4 x i32> %434, i32 %387, i64 1
  %436 = insertelement <4 x i32> %435, i32 %386, i64 2
  %437 = insertelement <4 x i32> %436, i32 %384, i64 3
  %438 = shl <4 x i32> %437, splat (i32 16)
  %439 = ashr <4 x i32> %438, splat (i32 24)
  %440 = shufflevector <4 x i32> %439, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %441 = mul nsw <4 x i32> %439, %440
  %442 = add nsw <4 x i32> %441, %433
  %443 = insertelement <4 x i32> poison, i32 %389, i64 0
  %444 = insertelement <4 x i32> %443, i32 %391, i64 1
  %445 = insertelement <4 x i32> %444, i32 %390, i64 2
  %446 = insertelement <4 x i32> %445, i32 %388, i64 3
  %447 = shl <4 x i32> %446, splat (i32 8)
  %448 = ashr <4 x i32> %447, splat (i32 24)
  %449 = shufflevector <4 x i32> %448, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %450 = mul nsw <4 x i32> %448, %449
  %451 = add nsw <4 x i32> %450, %442
  %452 = insertelement <4 x i32> poison, i32 %393, i64 0
  %453 = insertelement <4 x i32> %452, i32 %395, i64 1
  %454 = insertelement <4 x i32> %453, i32 %394, i64 2
  %455 = insertelement <4 x i32> %454, i32 %392, i64 3
  %456 = ashr <4 x i32> %455, splat (i32 24)
  %457 = shufflevector <4 x i32> %456, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %458 = mul nsw <4 x i32> %456, %457
  %459 = add nsw <4 x i32> %458, %451
  %460 = insertelement <4 x i32> poison, i32 %398, i64 0
  %461 = insertelement <4 x i32> %460, i32 %400, i64 1
  %462 = insertelement <4 x i32> %461, i32 %399, i64 2
  %463 = insertelement <4 x i32> %462, i32 %396, i64 3
  %464 = shl <4 x i32> %463, splat (i32 24)
  %465 = ashr exact <4 x i32> %464, splat (i32 24)
  %466 = shufflevector <4 x i32> %465, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %467 = mul nsw <4 x i32> %465, %466
  %468 = add nsw <4 x i32> %467, %459
  %469 = insertelement <4 x i32> poison, i32 %402, i64 0
  %470 = insertelement <4 x i32> %469, i32 %404, i64 1
  %471 = insertelement <4 x i32> %470, i32 %403, i64 2
  %472 = insertelement <4 x i32> %471, i32 %401, i64 3
  %473 = shl <4 x i32> %472, splat (i32 16)
  %474 = ashr <4 x i32> %473, splat (i32 24)
  %475 = shufflevector <4 x i32> %474, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %476 = mul nsw <4 x i32> %474, %475
  %477 = add nsw <4 x i32> %476, %468
  %478 = insertelement <4 x i32> poison, i32 %406, i64 0
  %479 = insertelement <4 x i32> %478, i32 %408, i64 1
  %480 = insertelement <4 x i32> %479, i32 %407, i64 2
  %481 = insertelement <4 x i32> %480, i32 %405, i64 3
  %482 = shl <4 x i32> %481, splat (i32 8)
  %483 = ashr <4 x i32> %482, splat (i32 24)
  %484 = shufflevector <4 x i32> %483, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %485 = mul nsw <4 x i32> %483, %484
  %486 = add nsw <4 x i32> %485, %477
  %487 = insertelement <4 x i32> poison, i32 %410, i64 0
  %488 = insertelement <4 x i32> %487, i32 %412, i64 1
  %489 = insertelement <4 x i32> %488, i32 %411, i64 2
  %490 = insertelement <4 x i32> %489, i32 %409, i64 3
  %491 = ashr <4 x i32> %490, splat (i32 24)
  %492 = shufflevector <4 x i32> %491, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  %493 = mul nsw <4 x i32> %491, %492
  %494 = add nsw <4 x i32> %493, %486
  %495 = shufflevector <4 x i32> %494, <4 x i32> poison, <4 x i32> <i32 2, i32 0, i32 3, i32 1>
  ret <4 x i32> %495
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x i32> @__zlift_ldmatrix_x4_b16(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = lshr i32 %2, 2
  %4 = and i32 %2, 3
  %5 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %11 = load i32, ptr addrspace(3) %10, align 4, !tbaa !5
  %12 = icmp eq i32 %4, 2
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %3) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef %3) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %3) #10
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %3) #10
  switch i32 %4, label %18 [
    i32 0, label %20
    i32 1, label %17
  ]

17:                                               ; preds = %1
  br label %20

18:                                               ; preds = %1
  %19 = select i1 %12, i32 %15, i32 %16
  br label %20

20:                                               ; preds = %18, %17, %1
  %21 = phi i32 [ %14, %17 ], [ %19, %18 ], [ %13, %1 ]
  %22 = add nuw nsw i32 %3, 8
  %23 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %22) #10
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef %22) #10
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %22) #10
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %22) #10
  switch i32 %4, label %28 [
    i32 0, label %30
    i32 1, label %27
  ]

27:                                               ; preds = %20
  br label %30

28:                                               ; preds = %20
  %29 = select i1 %12, i32 %25, i32 %26
  br label %30

30:                                               ; preds = %28, %27, %20
  %31 = phi i32 [ %24, %27 ], [ %29, %28 ], [ %23, %20 ]
  %32 = add nuw nsw i32 %3, 16
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %32) #10
  %34 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef %32) #10
  %35 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %32) #10
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %32) #10
  switch i32 %4, label %38 [
    i32 0, label %40
    i32 1, label %37
  ]

37:                                               ; preds = %30
  br label %40

38:                                               ; preds = %30
  %39 = select i1 %12, i32 %35, i32 %36
  br label %40

40:                                               ; preds = %38, %37, %30
  %41 = phi i32 [ %34, %37 ], [ %39, %38 ], [ %33, %30 ]
  %42 = add nuw nsw i32 %3, 24
  %43 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef %42) #10
  %44 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef %42) #10
  %45 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %42) #10
  %46 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %11, i32 noundef %42) #10
  switch i32 %4, label %48 [
    i32 0, label %50
    i32 1, label %47
  ]

47:                                               ; preds = %40
  br label %50

48:                                               ; preds = %40
  %49 = select i1 %12, i32 %45, i32 %46
  br label %50

50:                                               ; preds = %48, %47, %40
  %51 = phi i32 [ %44, %47 ], [ %49, %48 ], [ %43, %40 ]
  %52 = insertelement <4 x i32> poison, i32 %21, i64 0
  %53 = insertelement <4 x i32> %52, i32 %31, i64 1
  %54 = insertelement <4 x i32> %53, i32 %41, i64 2
  %55 = insertelement <4 x i32> %54, i32 %51, i64 3
  ret <4 x i32> %55
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zlift_ldmatrix_x1_b16(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %5 = load i32, ptr addrspace(3) %4, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = lshr i32 %2, 2
  %11 = and i32 %2, 3
  %12 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %10) #10
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %10) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %10) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %10) #10
  switch i32 %11, label %17 [
    i32 0, label %20
    i32 1, label %16
  ]

16:                                               ; preds = %1
  br label %20

17:                                               ; preds = %1
  %18 = icmp eq i32 %11, 2
  %19 = select i1 %18, i32 %14, i32 %15
  br label %20

20:                                               ; preds = %17, %16, %1
  %21 = phi i32 [ %13, %16 ], [ %19, %17 ], [ %12, %1 ]
  ret i32 %21
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zlift_ldmatrix_x2_b16(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %5 = load i32, ptr addrspace(3) %4, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = lshr i32 %2, 2
  %11 = and i32 %2, 3
  %12 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %10) #10
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %10) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %10) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %10) #10
  switch i32 %11, label %17 [
    i32 0, label %20
    i32 1, label %16
  ]

16:                                               ; preds = %1
  br label %20

17:                                               ; preds = %1
  %18 = icmp eq i32 %11, 2
  %19 = select i1 %18, i32 %14, i32 %15
  br label %20

20:                                               ; preds = %17, %16, %1
  %21 = phi i32 [ %13, %16 ], [ %19, %17 ], [ %12, %1 ]
  %22 = add nuw nsw i32 %10, 8
  %23 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %22) #10
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %22) #10
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %22) #10
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %22) #10
  switch i32 %11, label %28 [
    i32 0, label %31
    i32 1, label %27
  ]

27:                                               ; preds = %20
  br label %31

28:                                               ; preds = %20
  %29 = icmp eq i32 %11, 2
  %30 = select i1 %29, i32 %25, i32 %26
  br label %31

31:                                               ; preds = %28, %27, %20
  %32 = phi i32 [ %24, %27 ], [ %30, %28 ], [ %23, %20 ]
  %33 = insertelement <2 x i32> poison, i32 %21, i64 0
  %34 = insertelement <2 x i32> %33, i32 %32, i64 1
  ret <2 x i32> %34
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zlift_ldmatrix_x1_trans_b16(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %5 = load i32, ptr addrspace(3) %4, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = shl i32 %2, 1
  %11 = and i32 %10, 6
  %12 = lshr i32 %2, 3
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %11) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %11) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %11) #10
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %11) #10
  switch i32 %12, label %18 [
    i32 0, label %21
    i32 1, label %17
  ]

17:                                               ; preds = %1
  br label %21

18:                                               ; preds = %1
  %19 = icmp eq i32 %12, 2
  %20 = select i1 %19, i32 %15, i32 %16
  br label %21

21:                                               ; preds = %18, %17, %1
  %22 = phi i32 [ %14, %17 ], [ %20, %18 ], [ %13, %1 ]
  %23 = or disjoint i32 %11, 1
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %23) #10
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %23) #10
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %23) #10
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %23) #10
  switch i32 %12, label %29 [
    i32 0, label %32
    i32 1, label %28
  ]

28:                                               ; preds = %21
  br label %32

29:                                               ; preds = %21
  %30 = icmp eq i32 %12, 2
  %31 = select i1 %30, i32 %26, i32 %27
  br label %32

32:                                               ; preds = %29, %28, %21
  %33 = phi i32 [ %25, %28 ], [ %31, %29 ], [ %24, %21 ]
  %34 = shl i32 %2, 2
  %35 = and i32 %34, 16
  %36 = lshr i32 %22, %35
  %37 = and i32 %36, 65535
  %38 = lshr i32 %33, %35
  %39 = shl i32 %38, 16
  %40 = or disjoint i32 %39, %37
  ret i32 %40
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zlift_ldmatrix_x2_trans_b16(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %5 = load i32, ptr addrspace(3) %4, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = shl i32 %2, 1
  %11 = and i32 %10, 6
  %12 = lshr i32 %2, 3
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %11) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %11) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %11) #10
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %11) #10
  switch i32 %12, label %18 [
    i32 0, label %21
    i32 1, label %17
  ]

17:                                               ; preds = %1
  br label %21

18:                                               ; preds = %1
  %19 = icmp eq i32 %12, 2
  %20 = select i1 %19, i32 %15, i32 %16
  br label %21

21:                                               ; preds = %18, %17, %1
  %22 = phi i32 [ %14, %17 ], [ %20, %18 ], [ %13, %1 ]
  %23 = or disjoint i32 %11, 1
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %23) #10
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %23) #10
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %23) #10
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %23) #10
  switch i32 %12, label %29 [
    i32 0, label %32
    i32 1, label %28
  ]

28:                                               ; preds = %21
  br label %32

29:                                               ; preds = %21
  %30 = icmp eq i32 %12, 2
  %31 = select i1 %30, i32 %26, i32 %27
  br label %32

32:                                               ; preds = %29, %28, %21
  %33 = phi i32 [ %25, %28 ], [ %31, %29 ], [ %24, %21 ]
  %34 = or disjoint i32 %11, 8
  %35 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %34) #10
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %34) #10
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %34) #10
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %34) #10
  switch i32 %12, label %40 [
    i32 0, label %43
    i32 1, label %39
  ]

39:                                               ; preds = %32
  br label %43

40:                                               ; preds = %32
  %41 = icmp eq i32 %12, 2
  %42 = select i1 %41, i32 %37, i32 %38
  br label %43

43:                                               ; preds = %40, %39, %32
  %44 = phi i32 [ %36, %39 ], [ %42, %40 ], [ %35, %32 ]
  %45 = or disjoint i32 %11, 9
  %46 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %45) #10
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %45) #10
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %45) #10
  %49 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %45) #10
  switch i32 %12, label %51 [
    i32 0, label %54
    i32 1, label %50
  ]

50:                                               ; preds = %43
  br label %54

51:                                               ; preds = %43
  %52 = icmp eq i32 %12, 2
  %53 = select i1 %52, i32 %48, i32 %49
  br label %54

54:                                               ; preds = %51, %50, %43
  %55 = phi i32 [ %47, %50 ], [ %53, %51 ], [ %46, %43 ]
  %56 = shl i32 %2, 2
  %57 = and i32 %56, 16
  %58 = insertelement <2 x i32> poison, i32 %22, i64 0
  %59 = insertelement <2 x i32> %58, i32 %44, i64 1
  %60 = insertelement <2 x i32> poison, i32 %57, i64 0
  %61 = shufflevector <2 x i32> %60, <2 x i32> poison, <2 x i32> zeroinitializer
  %62 = lshr <2 x i32> %59, %61
  %63 = and <2 x i32> %62, splat (i32 65535)
  %64 = insertelement <2 x i32> poison, i32 %33, i64 0
  %65 = insertelement <2 x i32> %64, i32 %55, i64 1
  %66 = lshr <2 x i32> %65, %61
  %67 = shl <2 x i32> %66, splat (i32 16)
  %68 = or disjoint <2 x i32> %67, %63
  ret <2 x i32> %68
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <4 x i32> @__zlift_ldmatrix_x4_trans_b16(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %5 = load i32, ptr addrspace(3) %4, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = shl i32 %2, 1
  %11 = and i32 %10, 6
  %12 = lshr i32 %2, 3
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %11) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %11) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %11) #10
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %11) #10
  switch i32 %12, label %18 [
    i32 0, label %21
    i32 1, label %17
  ]

17:                                               ; preds = %1
  br label %21

18:                                               ; preds = %1
  %19 = icmp eq i32 %12, 2
  %20 = select i1 %19, i32 %15, i32 %16
  br label %21

21:                                               ; preds = %18, %17, %1
  %22 = phi i32 [ %14, %17 ], [ %20, %18 ], [ %13, %1 ]
  %23 = or disjoint i32 %11, 1
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %23) #10
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %23) #10
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %23) #10
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %23) #10
  switch i32 %12, label %29 [
    i32 0, label %32
    i32 1, label %28
  ]

28:                                               ; preds = %21
  br label %32

29:                                               ; preds = %21
  %30 = icmp eq i32 %12, 2
  %31 = select i1 %30, i32 %26, i32 %27
  br label %32

32:                                               ; preds = %29, %28, %21
  %33 = phi i32 [ %25, %28 ], [ %31, %29 ], [ %24, %21 ]
  %34 = or disjoint i32 %11, 8
  %35 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %34) #10
  %36 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %34) #10
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %34) #10
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %34) #10
  switch i32 %12, label %40 [
    i32 0, label %43
    i32 1, label %39
  ]

39:                                               ; preds = %32
  br label %43

40:                                               ; preds = %32
  %41 = icmp eq i32 %12, 2
  %42 = select i1 %41, i32 %37, i32 %38
  br label %43

43:                                               ; preds = %40, %39, %32
  %44 = phi i32 [ %36, %39 ], [ %42, %40 ], [ %35, %32 ]
  %45 = or disjoint i32 %11, 9
  %46 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %45) #10
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %45) #10
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %45) #10
  %49 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %45) #10
  switch i32 %12, label %51 [
    i32 0, label %54
    i32 1, label %50
  ]

50:                                               ; preds = %43
  br label %54

51:                                               ; preds = %43
  %52 = icmp eq i32 %12, 2
  %53 = select i1 %52, i32 %48, i32 %49
  br label %54

54:                                               ; preds = %51, %50, %43
  %55 = phi i32 [ %47, %50 ], [ %53, %51 ], [ %46, %43 ]
  %56 = or disjoint i32 %11, 16
  %57 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %56) #10
  %58 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %56) #10
  %59 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %56) #10
  %60 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %56) #10
  switch i32 %12, label %62 [
    i32 0, label %65
    i32 1, label %61
  ]

61:                                               ; preds = %54
  br label %65

62:                                               ; preds = %54
  %63 = icmp eq i32 %12, 2
  %64 = select i1 %63, i32 %59, i32 %60
  br label %65

65:                                               ; preds = %62, %61, %54
  %66 = phi i32 [ %58, %61 ], [ %64, %62 ], [ %57, %54 ]
  %67 = or disjoint i32 %11, 17
  %68 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %67) #10
  %69 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %67) #10
  %70 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %67) #10
  %71 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %67) #10
  switch i32 %12, label %73 [
    i32 0, label %76
    i32 1, label %72
  ]

72:                                               ; preds = %65
  br label %76

73:                                               ; preds = %65
  %74 = icmp eq i32 %12, 2
  %75 = select i1 %74, i32 %70, i32 %71
  br label %76

76:                                               ; preds = %73, %72, %65
  %77 = phi i32 [ %69, %72 ], [ %75, %73 ], [ %68, %65 ]
  %78 = or disjoint i32 %11, 24
  %79 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %78) #10
  %80 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %78) #10
  %81 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %78) #10
  %82 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %78) #10
  switch i32 %12, label %84 [
    i32 0, label %87
    i32 1, label %83
  ]

83:                                               ; preds = %76
  br label %87

84:                                               ; preds = %76
  %85 = icmp eq i32 %12, 2
  %86 = select i1 %85, i32 %81, i32 %82
  br label %87

87:                                               ; preds = %84, %83, %76
  %88 = phi i32 [ %80, %83 ], [ %86, %84 ], [ %79, %76 ]
  %89 = or disjoint i32 %11, 25
  %90 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %89) #10
  %91 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %89) #10
  %92 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %89) #10
  %93 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 32) %89) #10
  switch i32 %12, label %95 [
    i32 0, label %98
    i32 1, label %94
  ]

94:                                               ; preds = %87
  br label %98

95:                                               ; preds = %87
  %96 = icmp eq i32 %12, 2
  %97 = select i1 %96, i32 %92, i32 %93
  br label %98

98:                                               ; preds = %95, %94, %87
  %99 = phi i32 [ %91, %94 ], [ %97, %95 ], [ %90, %87 ]
  %100 = shl i32 %2, 2
  %101 = and i32 %100, 16
  %102 = insertelement <4 x i32> poison, i32 %22, i64 0
  %103 = insertelement <4 x i32> %102, i32 %44, i64 1
  %104 = insertelement <4 x i32> %103, i32 %66, i64 2
  %105 = insertelement <4 x i32> %104, i32 %88, i64 3
  %106 = insertelement <4 x i32> poison, i32 %101, i64 0
  %107 = shufflevector <4 x i32> %106, <4 x i32> poison, <4 x i32> zeroinitializer
  %108 = lshr <4 x i32> %105, %107
  %109 = and <4 x i32> %108, splat (i32 65535)
  %110 = insertelement <4 x i32> poison, i32 %33, i64 0
  %111 = insertelement <4 x i32> %110, i32 %55, i64 1
  %112 = insertelement <4 x i32> %111, i32 %77, i64 2
  %113 = insertelement <4 x i32> %112, i32 %99, i64 3
  %114 = lshr <4 x i32> %113, %107
  %115 = shl <4 x i32> %114, splat (i32 16)
  %116 = or disjoint <4 x i32> %115, %109
  ret <4 x i32> %116
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_stmatrix_x1_b16(ptr addrspace(3) nocapture noundef writeonly %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %4 = shl i32 %3, 2
  %5 = and i32 %4, 28
  %6 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %5) #10
  %7 = or disjoint i32 %5, 1
  %8 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %9 = or disjoint i32 %5, 2
  %10 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %9) #10
  %11 = or disjoint i32 %5, 3
  %12 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %11) #10
  %13 = icmp ult i32 %3, 8
  br i1 %13, label %14, label %18

14:                                               ; preds = %2
  store i32 %6, ptr addrspace(3) %0, align 4, !tbaa !5
  %15 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %8, ptr addrspace(3) %15, align 4, !tbaa !5
  %16 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  store i32 %10, ptr addrspace(3) %16, align 4, !tbaa !5
  %17 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  store i32 %12, ptr addrspace(3) %17, align 4, !tbaa !5
  br label %18

18:                                               ; preds = %14, %2
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_stmatrix_x2_b16(ptr addrspace(3) nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 3
  %6 = shl i32 %4, 2
  %7 = and i32 %6, 28
  %8 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %9 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %7) #10
  switch i32 %5, label %11 [
    i32 0, label %12
    i32 1, label %10
  ]

10:                                               ; preds = %3
  br label %12

11:                                               ; preds = %3
  br label %12

12:                                               ; preds = %11, %10, %3
  %13 = phi i32 [ %9, %10 ], [ 0, %11 ], [ %8, %3 ]
  %14 = or disjoint i32 %7, 1
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %14) #10
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %14) #10
  switch i32 %5, label %18 [
    i32 0, label %19
    i32 1, label %17
  ]

17:                                               ; preds = %12
  br label %19

18:                                               ; preds = %12
  br label %19

19:                                               ; preds = %18, %17, %12
  %20 = phi i32 [ %16, %17 ], [ 0, %18 ], [ %15, %12 ]
  %21 = or disjoint i32 %7, 2
  %22 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %21) #10
  %23 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %21) #10
  switch i32 %5, label %25 [
    i32 0, label %26
    i32 1, label %24
  ]

24:                                               ; preds = %19
  br label %26

25:                                               ; preds = %19
  br label %26

26:                                               ; preds = %25, %24, %19
  %27 = phi i32 [ %23, %24 ], [ 0, %25 ], [ %22, %19 ]
  %28 = or disjoint i32 %7, 3
  %29 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %28) #10
  %30 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %28) #10
  switch i32 %5, label %32 [
    i32 0, label %33
    i32 1, label %31
  ]

31:                                               ; preds = %26
  br label %33

32:                                               ; preds = %26
  br label %33

33:                                               ; preds = %32, %31, %26
  %34 = phi i32 [ %30, %31 ], [ 0, %32 ], [ %29, %26 ]
  %35 = icmp ult i32 %4, 16
  br i1 %35, label %36, label %40

36:                                               ; preds = %33
  store i32 %13, ptr addrspace(3) %0, align 4, !tbaa !5
  %37 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %20, ptr addrspace(3) %37, align 4, !tbaa !5
  %38 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  store i32 %27, ptr addrspace(3) %38, align 4, !tbaa !5
  %39 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  store i32 %34, ptr addrspace(3) %39, align 4, !tbaa !5
  br label %40

40:                                               ; preds = %36, %33
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_stmatrix_x4_b16(ptr addrspace(3) nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = lshr i32 %6, 3
  %8 = shl i32 %6, 2
  %9 = and i32 %8, 28
  %10 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %9) #10
  %11 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %9) #10
  %12 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %9) #10
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %9) #10
  switch i32 %7, label %15 [
    i32 0, label %18
    i32 1, label %14
  ]

14:                                               ; preds = %5
  br label %18

15:                                               ; preds = %5
  %16 = icmp eq i32 %7, 2
  %17 = select i1 %16, i32 %12, i32 %13
  br label %18

18:                                               ; preds = %15, %14, %5
  %19 = phi i32 [ %11, %14 ], [ %17, %15 ], [ %10, %5 ]
  %20 = or disjoint i32 %9, 1
  %21 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %20) #10
  %22 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %20) #10
  %23 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %20) #10
  %24 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %20) #10
  switch i32 %7, label %26 [
    i32 0, label %29
    i32 1, label %25
  ]

25:                                               ; preds = %18
  br label %29

26:                                               ; preds = %18
  %27 = icmp eq i32 %7, 2
  %28 = select i1 %27, i32 %23, i32 %24
  br label %29

29:                                               ; preds = %26, %25, %18
  %30 = phi i32 [ %22, %25 ], [ %28, %26 ], [ %21, %18 ]
  %31 = or disjoint i32 %9, 2
  %32 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %31) #10
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %31) #10
  %34 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %31) #10
  %35 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %31) #10
  switch i32 %7, label %37 [
    i32 0, label %40
    i32 1, label %36
  ]

36:                                               ; preds = %29
  br label %40

37:                                               ; preds = %29
  %38 = icmp eq i32 %7, 2
  %39 = select i1 %38, i32 %34, i32 %35
  br label %40

40:                                               ; preds = %37, %36, %29
  %41 = phi i32 [ %33, %36 ], [ %39, %37 ], [ %32, %29 ]
  %42 = or disjoint i32 %9, 3
  %43 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %42) #10
  %44 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %42) #10
  %45 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %42) #10
  %46 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %42) #10
  switch i32 %7, label %48 [
    i32 0, label %51
    i32 1, label %47
  ]

47:                                               ; preds = %40
  br label %51

48:                                               ; preds = %40
  %49 = icmp eq i32 %7, 2
  %50 = select i1 %49, i32 %45, i32 %46
  br label %51

51:                                               ; preds = %48, %47, %40
  %52 = phi i32 [ %44, %47 ], [ %50, %48 ], [ %43, %40 ]
  %53 = icmp ult i32 %6, 32
  br i1 %53, label %54, label %58

54:                                               ; preds = %51
  store i32 %19, ptr addrspace(3) %0, align 4, !tbaa !5
  %55 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %30, ptr addrspace(3) %55, align 4, !tbaa !5
  %56 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  store i32 %41, ptr addrspace(3) %56, align 4, !tbaa !5
  %57 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  store i32 %52, ptr addrspace(3) %57, align 4, !tbaa !5
  br label %58

58:                                               ; preds = %54, %51
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_stmatrix_x1_trans_b16(ptr addrspace(3) nocapture noundef writeonly %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %4 = lshr i32 %3, 1
  %5 = and i32 %4, 3
  %6 = icmp ult i32 %3, 8
  %7 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %5) #10
  %8 = or disjoint i32 %5, 4
  %9 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %8) #10
  %10 = or disjoint i32 %5, 8
  %11 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %10) #10
  %12 = or disjoint i32 %5, 12
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %12) #10
  %14 = or disjoint i32 %5, 16
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %14) #10
  %16 = or disjoint i32 %5, 20
  %17 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %16) #10
  %18 = or disjoint i32 %5, 24
  %19 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %18) #10
  %20 = or disjoint i32 %5, 28
  %21 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %20) #10
  br i1 %6, label %22, label %48

22:                                               ; preds = %2
  %23 = shl nuw nsw i32 %3, 4
  %24 = and i32 %23, 16
  %25 = lshr i32 %9, %24
  %26 = shl i32 %25, 16
  %27 = lshr i32 %7, %24
  %28 = and i32 %27, 65535
  %29 = or disjoint i32 %26, %28
  %30 = lshr i32 %17, %24
  %31 = shl i32 %30, 16
  %32 = lshr i32 %15, %24
  %33 = and i32 %32, 65535
  %34 = or disjoint i32 %31, %33
  %35 = lshr i32 %21, %24
  %36 = shl i32 %35, 16
  %37 = lshr i32 %19, %24
  %38 = and i32 %37, 65535
  %39 = or disjoint i32 %36, %38
  %40 = lshr i32 %13, %24
  %41 = shl i32 %40, 16
  %42 = lshr i32 %11, %24
  %43 = and i32 %42, 65535
  %44 = or disjoint i32 %41, %43
  store i32 %29, ptr addrspace(3) %0, align 4, !tbaa !5
  %45 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %44, ptr addrspace(3) %45, align 4, !tbaa !5
  %46 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  store i32 %34, ptr addrspace(3) %46, align 4, !tbaa !5
  %47 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  store i32 %39, ptr addrspace(3) %47, align 4, !tbaa !5
  br label %48

48:                                               ; preds = %22, %2
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_stmatrix_x2_trans_b16(ptr addrspace(3) nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = and i32 %4, 7
  %6 = lshr i32 %4, 3
  %7 = lshr i32 %5, 1
  %8 = shl nuw nsw i32 %5, 4
  %9 = and i32 %8, 16
  %10 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %7) #10
  %11 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %7) #10
  switch i32 %6, label %13 [
    i32 0, label %14
    i32 1, label %12
  ]

12:                                               ; preds = %3
  br label %14

13:                                               ; preds = %3
  br label %14

14:                                               ; preds = %13, %12, %3
  %15 = phi i32 [ %11, %12 ], [ 0, %13 ], [ %10, %3 ]
  %16 = lshr i32 %15, %9
  %17 = and i32 %16, 65535
  %18 = or disjoint i32 %7, 4
  %19 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %18) #10
  %20 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %18) #10
  switch i32 %6, label %22 [
    i32 0, label %23
    i32 1, label %21
  ]

21:                                               ; preds = %14
  br label %23

22:                                               ; preds = %14
  br label %23

23:                                               ; preds = %22, %21, %14
  %24 = phi i32 [ %20, %21 ], [ 0, %22 ], [ %19, %14 ]
  %25 = lshr i32 %24, %9
  %26 = shl i32 %25, 16
  %27 = or disjoint i32 %7, 8
  %28 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %27) #10
  %29 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %27) #10
  switch i32 %6, label %31 [
    i32 0, label %32
    i32 1, label %30
  ]

30:                                               ; preds = %23
  br label %32

31:                                               ; preds = %23
  br label %32

32:                                               ; preds = %31, %30, %23
  %33 = phi i32 [ %29, %30 ], [ 0, %31 ], [ %28, %23 ]
  %34 = lshr i32 %33, %9
  %35 = and i32 %34, 65535
  %36 = or disjoint i32 %7, 12
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %36) #10
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %36) #10
  switch i32 %6, label %40 [
    i32 0, label %41
    i32 1, label %39
  ]

39:                                               ; preds = %32
  br label %41

40:                                               ; preds = %32
  br label %41

41:                                               ; preds = %40, %39, %32
  %42 = phi i32 [ %38, %39 ], [ 0, %40 ], [ %37, %32 ]
  %43 = lshr i32 %42, %9
  %44 = shl i32 %43, 16
  %45 = or disjoint i32 %44, %35
  %46 = or disjoint i32 %7, 16
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %46) #10
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %46) #10
  switch i32 %6, label %50 [
    i32 0, label %51
    i32 1, label %49
  ]

49:                                               ; preds = %41
  br label %51

50:                                               ; preds = %41
  br label %51

51:                                               ; preds = %50, %49, %41
  %52 = phi i32 [ %48, %49 ], [ 0, %50 ], [ %47, %41 ]
  %53 = lshr i32 %52, %9
  %54 = and i32 %53, 65535
  %55 = or disjoint i32 %7, 20
  %56 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %55) #10
  %57 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %55) #10
  switch i32 %6, label %59 [
    i32 0, label %60
    i32 1, label %58
  ]

58:                                               ; preds = %51
  br label %60

59:                                               ; preds = %51
  br label %60

60:                                               ; preds = %59, %58, %51
  %61 = phi i32 [ %57, %58 ], [ 0, %59 ], [ %56, %51 ]
  %62 = lshr i32 %61, %9
  %63 = shl i32 %62, 16
  %64 = or disjoint i32 %63, %54
  %65 = or disjoint i32 %7, 24
  %66 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %65) #10
  %67 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %65) #10
  switch i32 %6, label %69 [
    i32 0, label %70
    i32 1, label %68
  ]

68:                                               ; preds = %60
  br label %70

69:                                               ; preds = %60
  br label %70

70:                                               ; preds = %69, %68, %60
  %71 = phi i32 [ %67, %68 ], [ 0, %69 ], [ %66, %60 ]
  %72 = lshr i32 %71, %9
  %73 = and i32 %72, 65535
  %74 = or disjoint i32 %7, 28
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %74) #10
  %76 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %74) #10
  switch i32 %6, label %78 [
    i32 0, label %79
    i32 1, label %77
  ]

77:                                               ; preds = %70
  br label %79

78:                                               ; preds = %70
  br label %79

79:                                               ; preds = %78, %77, %70
  %80 = phi i32 [ %76, %77 ], [ 0, %78 ], [ %75, %70 ]
  %81 = icmp ult i32 %4, 16
  br i1 %81, label %82, label %90

82:                                               ; preds = %79
  %83 = or disjoint i32 %26, %17
  %84 = lshr i32 %80, %9
  %85 = shl i32 %84, 16
  %86 = or disjoint i32 %85, %73
  store i32 %83, ptr addrspace(3) %0, align 4, !tbaa !5
  %87 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %45, ptr addrspace(3) %87, align 4, !tbaa !5
  %88 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  store i32 %64, ptr addrspace(3) %88, align 4, !tbaa !5
  %89 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  store i32 %86, ptr addrspace(3) %89, align 4, !tbaa !5
  br label %90

90:                                               ; preds = %82, %79
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_stmatrix_x4_trans_b16(ptr addrspace(3) nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = and i32 %6, 7
  %8 = lshr i32 %6, 3
  %9 = lshr i32 %7, 1
  %10 = icmp eq i32 %8, 2
  %11 = shl nuw nsw i32 %7, 4
  %12 = and i32 %11, 16
  %13 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %9) #10
  %14 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %9) #10
  %15 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %9) #10
  %16 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %9) #10
  switch i32 %8, label %18 [
    i32 0, label %20
    i32 1, label %17
  ]

17:                                               ; preds = %5
  br label %20

18:                                               ; preds = %5
  %19 = select i1 %10, i32 %15, i32 %16
  br label %20

20:                                               ; preds = %18, %17, %5
  %21 = phi i32 [ %14, %17 ], [ %19, %18 ], [ %13, %5 ]
  %22 = lshr i32 %21, %12
  %23 = and i32 %22, 65535
  %24 = or disjoint i32 %9, 4
  %25 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %24) #10
  %26 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %24) #10
  %27 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %24) #10
  %28 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %24) #10
  switch i32 %8, label %30 [
    i32 0, label %32
    i32 1, label %29
  ]

29:                                               ; preds = %20
  br label %32

30:                                               ; preds = %20
  %31 = select i1 %10, i32 %27, i32 %28
  br label %32

32:                                               ; preds = %30, %29, %20
  %33 = phi i32 [ %26, %29 ], [ %31, %30 ], [ %25, %20 ]
  %34 = lshr i32 %33, %12
  %35 = shl i32 %34, 16
  %36 = or disjoint i32 %9, 8
  %37 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %36) #10
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %36) #10
  %39 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %36) #10
  %40 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %36) #10
  switch i32 %8, label %42 [
    i32 0, label %44
    i32 1, label %41
  ]

41:                                               ; preds = %32
  br label %44

42:                                               ; preds = %32
  %43 = select i1 %10, i32 %39, i32 %40
  br label %44

44:                                               ; preds = %42, %41, %32
  %45 = phi i32 [ %38, %41 ], [ %43, %42 ], [ %37, %32 ]
  %46 = lshr i32 %45, %12
  %47 = and i32 %46, 65535
  %48 = or disjoint i32 %9, 12
  %49 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %48) #10
  %50 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %48) #10
  %51 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %48) #10
  %52 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %48) #10
  switch i32 %8, label %54 [
    i32 0, label %56
    i32 1, label %53
  ]

53:                                               ; preds = %44
  br label %56

54:                                               ; preds = %44
  %55 = select i1 %10, i32 %51, i32 %52
  br label %56

56:                                               ; preds = %54, %53, %44
  %57 = phi i32 [ %50, %53 ], [ %55, %54 ], [ %49, %44 ]
  %58 = lshr i32 %57, %12
  %59 = shl i32 %58, 16
  %60 = or disjoint i32 %59, %47
  %61 = or disjoint i32 %9, 16
  %62 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %61) #10
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %61) #10
  %64 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %61) #10
  %65 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %61) #10
  switch i32 %8, label %67 [
    i32 0, label %69
    i32 1, label %66
  ]

66:                                               ; preds = %56
  br label %69

67:                                               ; preds = %56
  %68 = select i1 %10, i32 %64, i32 %65
  br label %69

69:                                               ; preds = %67, %66, %56
  %70 = phi i32 [ %63, %66 ], [ %68, %67 ], [ %62, %56 ]
  %71 = lshr i32 %70, %12
  %72 = and i32 %71, 65535
  %73 = or disjoint i32 %9, 20
  %74 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %73) #10
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %73) #10
  %76 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %73) #10
  %77 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %73) #10
  switch i32 %8, label %79 [
    i32 0, label %81
    i32 1, label %78
  ]

78:                                               ; preds = %69
  br label %81

79:                                               ; preds = %69
  %80 = select i1 %10, i32 %76, i32 %77
  br label %81

81:                                               ; preds = %79, %78, %69
  %82 = phi i32 [ %75, %78 ], [ %80, %79 ], [ %74, %69 ]
  %83 = lshr i32 %82, %12
  %84 = shl i32 %83, 16
  %85 = or disjoint i32 %84, %72
  %86 = or disjoint i32 %9, 24
  %87 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %86) #10
  %88 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %86) #10
  %89 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %86) #10
  %90 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %86) #10
  switch i32 %8, label %92 [
    i32 0, label %94
    i32 1, label %91
  ]

91:                                               ; preds = %81
  br label %94

92:                                               ; preds = %81
  %93 = select i1 %10, i32 %89, i32 %90
  br label %94

94:                                               ; preds = %92, %91, %81
  %95 = phi i32 [ %88, %91 ], [ %93, %92 ], [ %87, %81 ]
  %96 = lshr i32 %95, %12
  %97 = and i32 %96, 65535
  %98 = or disjoint i32 %9, 28
  %99 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef %98) #10
  %100 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef %98) #10
  %101 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef %98) #10
  %102 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef %98) #10
  switch i32 %8, label %104 [
    i32 0, label %106
    i32 1, label %103
  ]

103:                                              ; preds = %94
  br label %106

104:                                              ; preds = %94
  %105 = select i1 %10, i32 %101, i32 %102
  br label %106

106:                                              ; preds = %104, %103, %94
  %107 = phi i32 [ %100, %103 ], [ %105, %104 ], [ %99, %94 ]
  %108 = icmp ult i32 %6, 32
  br i1 %108, label %109, label %117

109:                                              ; preds = %106
  %110 = or disjoint i32 %35, %23
  %111 = lshr i32 %107, %12
  %112 = shl i32 %111, 16
  %113 = or disjoint i32 %112, %97
  store i32 %110, ptr addrspace(3) %0, align 4, !tbaa !5
  %114 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %60, ptr addrspace(3) %114, align 4, !tbaa !5
  %115 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  store i32 %85, ptr addrspace(3) %115, align 4, !tbaa !5
  %116 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  store i32 %113, ptr addrspace(3) %116, align 4, !tbaa !5
  br label %117

117:                                              ; preds = %109, %106
  ret void
}

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtp_s32(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtpi(i32 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtpi(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtn_s32(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtni(i32 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtni(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtz_s32(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtzi(i32 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtzi(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtp_u32(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtpj(i32 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtpj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtn_u32(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtnj(i32 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtnj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtz_u32(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtzj(i32 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtzj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtp_s64(i64 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtpl(i64 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtpl(i64 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtn_s64(i64 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtnl(i64 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtnl(i64 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtz_s64(i64 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtzl(i64 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtzl(i64 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtp_u64(i64 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtpm(i64 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtpm(i64 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtn_u64(i64 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtnm(i64 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtnm(i64 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zlift_cvt_rtz_u64(i64 noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z17convert_float_rtzm(i64 noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z17convert_float_rtzm(i64 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func double @__zlift_rsqrt_approx_f64(double noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func double @_Z4sqrtd(double noundef %0) #11
  %3 = fdiv double 1.000000e+00, %2
  ret double %3
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func double @_Z4sqrtd(double noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func noundef double @__zlift_rcp_approx_f64(double noundef %0) local_unnamed_addr #3 {
  %2 = fdiv double 1.000000e+00, %0
  ret double %2
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func noundef i32 @__zlift_atom_add_f16x2(ptr addrspace(1) noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = bitcast i32 %1 to <2 x half>
  %4 = load volatile i32, ptr addrspace(1) %0, align 4, !tbaa !5
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i32 [ %4, %2 ], [ %10, %5 ]
  %7 = bitcast i32 %6 to <2 x half>
  %8 = fadd <2 x half> %3, %7
  %9 = bitcast <2 x half> %8 to i32
  %10 = tail call spir_func i32 @_Z14atomic_cmpxchgPU3AS1Vjjj(ptr addrspace(1) noundef %0, i32 noundef %6, i32 noundef %9) #10
  %11 = icmp eq i32 %10, %6
  br i1 %11, label %12, label %5

12:                                               ; preds = %5
  ret i32 %6
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z14atomic_cmpxchgPU3AS1Vjjj(ptr addrspace(1) noundef, i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write)
define linkonce_odr spir_func void @__zlift_mbarrier_init(ptr addrspace(3) nocapture noundef writeonly initializes((0, 8)) %0, i32 noundef %1) local_unnamed_addr #6 {
  store i32 %1, ptr addrspace(3) %0, align 4, !tbaa !5
  %3 = shl i32 %1, 1
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  store i32 %3, ptr addrspace(3) %4, align 4, !tbaa !5
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_mbarrier_arrive(ptr addrspace(3) noundef %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @_Z10atomic_decPU3AS3Vj(ptr addrspace(3) noundef %0) #10
  %3 = icmp eq i32 %2, 1
  br i1 %3, label %4, label %9

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %6 = load i32, ptr addrspace(3) %5, align 4, !tbaa !5
  %7 = lshr i32 %6, 1
  store i32 %7, ptr addrspace(3) %0, align 4, !tbaa !5
  tail call spir_func void @_Z9mem_fencej(i32 noundef 1) #10
  %8 = xor i32 %6, 1
  store i32 %8, ptr addrspace(3) %5, align 4, !tbaa !5
  br label %9

9:                                                ; preds = %4, %1
  ret void
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z10atomic_decPU3AS3Vj(ptr addrspace(3) noundef) local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z9mem_fencej(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func range(i32 0, 2) i32 @__zlift_mbarrier_try_wait(ptr addrspace(3) noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %4 = tail call spir_func i32 @_Z9atomic_orPU3AS3Vjj(ptr addrspace(3) noundef nonnull %3, i32 noundef 0) #10
  %5 = xor i32 %4, %1
  %6 = and i32 %5, 1
  ret i32 %6
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z9atomic_orPU3AS3Vjj(ptr addrspace(3) noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zlift_utma_load(ptr addrspace(1) noundef readonly %0, ptr addrspace(3) nocapture noundef writeonly %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6) local_unnamed_addr #0 {
  %8 = icmp ult ptr addrspace(1) %0, inttoptr (i64 65536 to ptr addrspace(1))
  br i1 %8, label %12, label %9

9:                                                ; preds = %7
  %10 = load i64, ptr addrspace(1) %0, align 8, !tbaa !9
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %12, label %17

12:                                               ; preds = %9, %7
  %13 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %220

15:                                               ; preds = %12
  store i8 -83, ptr addrspace(3) %1, align 1, !tbaa !12
  %16 = getelementptr inbounds nuw i8, ptr addrspace(3) %1, i64 1
  store i8 -34, ptr addrspace(3) %16, align 1, !tbaa !12
  br label %220

17:                                               ; preds = %9
  %18 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %19 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 8
  %20 = load i32, ptr addrspace(1) %19, align 8, !tbaa !13
  %21 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 12
  %22 = load i32, ptr addrspace(1) %21, align 4, !tbaa !14
  %23 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 16
  %24 = load i32, ptr addrspace(1) %23, align 8, !tbaa !15
  %25 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 24
  %26 = load i32, ptr addrspace(1) %25, align 8, !tbaa !16
  %27 = icmp eq i32 %26, 0
  %28 = select i1 %27, i32 %22, i32 %26
  %29 = sext i32 %5 to i64
  %30 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 36
  %31 = load i32, ptr addrspace(1) %30, align 4, !tbaa !17
  %32 = sext i32 %31 to i64
  %33 = mul nsw i64 %32, %29
  %34 = sext i32 %6 to i64
  %35 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 40
  %36 = load i32, ptr addrspace(1) %35, align 8, !tbaa !18
  %37 = sext i32 %36 to i64
  %38 = mul nsw i64 %37, %34
  %39 = add nsw i64 %38, %33
  %40 = load i64, ptr addrspace(1) %0, align 8, !tbaa !9
  %41 = inttoptr i64 %40 to ptr addrspace(1)
  %42 = sext i32 %24 to i64
  %43 = mul nsw i64 %39, %42
  %44 = getelementptr inbounds nuw i8, ptr addrspace(1) %41, i64 %43
  %45 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 20
  %46 = load i32, ptr addrspace(1) %45, align 4, !tbaa !19
  switch i32 %46, label %169 [
    i32 4, label %47
    i32 3, label %83
  ]

47:                                               ; preds = %17
  %48 = icmp sgt i32 %20, 0
  br i1 %48, label %49, label %220

49:                                               ; preds = %47
  %50 = icmp sgt i32 %22, 0
  %51 = icmp sgt i32 %24, 0
  br label %52

52:                                               ; preds = %59, %49
  %53 = phi i32 [ 0, %49 ], [ %60, %59 ]
  br i1 %50, label %54, label %59

54:                                               ; preds = %52
  %55 = mul nuw nsw i32 %53, %22
  %56 = add nsw i32 %53, %4
  %57 = mul nsw i32 %56, %28
  %58 = add i32 %57, %3
  br label %62

59:                                               ; preds = %80, %52
  %60 = add nuw nsw i32 %53, 1
  %61 = icmp slt i32 %60, %20
  br i1 %61, label %52, label %220

62:                                               ; preds = %80, %54
  %63 = phi i32 [ 0, %54 ], [ %81, %80 ]
  %64 = add nuw nsw i32 %63, %55
  %65 = mul nsw i32 %64, %24
  %66 = add i32 %58, %63
  %67 = sext i32 %66 to i64
  %68 = mul nsw i64 %67, %42
  %69 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 %68
  br i1 %51, label %70, label %80

70:                                               ; preds = %70, %62
  %71 = phi i32 [ %78, %70 ], [ 0, %62 ]
  %72 = zext nneg i32 %71 to i64
  %73 = getelementptr inbounds nuw i8, ptr addrspace(1) %69, i64 %72
  %74 = load i8, ptr addrspace(1) %73, align 1, !tbaa !12
  %75 = add nuw nsw i32 %71, %65
  %76 = zext nneg i32 %75 to i64
  %77 = getelementptr inbounds nuw i8, ptr addrspace(3) %1, i64 %76
  store i8 %74, ptr addrspace(3) %77, align 1, !tbaa !12
  %78 = add nuw nsw i32 %71, 1
  %79 = icmp slt i32 %78, %24
  br i1 %79, label %70, label %80

80:                                               ; preds = %70, %62
  %81 = add nuw nsw i32 %63, 1
  %82 = icmp slt i32 %81, %22
  br i1 %82, label %62, label %59

83:                                               ; preds = %17
  %84 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 32
  %85 = load i32, ptr addrspace(1) %84, align 8, !tbaa !20
  %86 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 52
  %87 = load i32, ptr addrspace(1) %86, align 4, !tbaa !21
  %88 = icmp eq i32 %87, 0
  %89 = icmp eq i32 %24, 1
  %90 = and i32 %87, 31
  %91 = select i1 %88, i32 3, i32 %90
  %92 = shl i32 8, %91
  %93 = select i1 %89, i32 128, i32 %92
  %94 = icmp sgt i32 %20, 0
  br i1 %94, label %95, label %220

95:                                               ; preds = %83
  %96 = icmp sgt i32 %85, 0
  %97 = icmp sgt i32 %22, 0
  %98 = add nuw nsw i32 %91, 3
  %99 = select i1 %89, i32 7, i32 %98
  %100 = mul nsw i32 %93, %20
  %101 = shl nsw i32 -1, %91
  %102 = xor i32 %101, -1
  %103 = icmp sgt i32 %24, 0
  %104 = icmp ult i32 %24, 4
  %105 = and i32 %24, 2147483644
  %106 = icmp eq i32 %24, %105
  br label %107

107:                                              ; preds = %116, %95
  %108 = phi i32 [ 0, %95 ], [ %117, %116 ]
  %109 = add nsw i32 %108, %4
  %110 = icmp sge i32 %109, %85
  %111 = select i1 %96, i1 %110, i1 false
  br i1 %97, label %112, label %116

112:                                              ; preds = %107
  %113 = mul nsw i32 %108, %93
  %114 = mul nsw i32 %109, %28
  %115 = add i32 %114, %3
  br label %119

116:                                              ; preds = %166, %107
  %117 = add nuw nsw i32 %108, 1
  %118 = icmp slt i32 %117, %20
  br i1 %118, label %107, label %220

119:                                              ; preds = %166, %112
  %120 = phi i32 [ 0, %112 ], [ %167, %166 ]
  %121 = lshr i32 %120, %99
  %122 = mul nsw i32 %100, %121
  %123 = srem i32 %120, %93
  %124 = add nsw i32 %123, %113
  %125 = ashr i32 %124, 7
  %126 = and i32 %125, %102
  %127 = shl i32 %126, 4
  %128 = xor i32 %127, %124
  %129 = add nsw i32 %128, %122
  br i1 %111, label %130, label %150

130:                                              ; preds = %119
  br i1 %103, label %131, label %166

131:                                              ; preds = %130
  %132 = mul nsw i32 %129, %24
  br i1 %104, label %141, label %133

133:                                              ; preds = %133, %131
  %134 = phi i32 [ %138, %133 ], [ 0, %131 ]
  %135 = add nsw i32 %134, %132
  %136 = sext i32 %135 to i64
  %137 = getelementptr inbounds i8, ptr addrspace(3) %1, i64 %136
  store <4 x i8> zeroinitializer, ptr addrspace(3) %137, align 1, !tbaa !12
  %138 = add nuw i32 %134, 4
  %139 = icmp eq i32 %138, %105
  br i1 %139, label %140, label %133, !llvm.loop !22

140:                                              ; preds = %133
  br i1 %106, label %166, label %141

141:                                              ; preds = %140, %131
  %142 = phi i32 [ 0, %131 ], [ %105, %140 ]
  br label %143

143:                                              ; preds = %143, %141
  %144 = phi i32 [ %148, %143 ], [ %142, %141 ]
  %145 = add nsw i32 %144, %132
  %146 = sext i32 %145 to i64
  %147 = getelementptr inbounds i8, ptr addrspace(3) %1, i64 %146
  store i8 0, ptr addrspace(3) %147, align 1, !tbaa !12
  %148 = add nuw nsw i32 %144, 1
  %149 = icmp slt i32 %148, %24
  br i1 %149, label %143, label %166, !llvm.loop !25

150:                                              ; preds = %119
  %151 = mul nsw i32 %129, %24
  %152 = add i32 %115, %120
  %153 = sext i32 %152 to i64
  %154 = mul nsw i64 %153, %42
  %155 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 %154
  br i1 %103, label %156, label %166

156:                                              ; preds = %156, %150
  %157 = phi i32 [ %164, %156 ], [ 0, %150 ]
  %158 = zext nneg i32 %157 to i64
  %159 = getelementptr inbounds nuw i8, ptr addrspace(1) %155, i64 %158
  %160 = load i8, ptr addrspace(1) %159, align 1, !tbaa !12
  %161 = add nsw i32 %157, %151
  %162 = sext i32 %161 to i64
  %163 = getelementptr inbounds i8, ptr addrspace(3) %1, i64 %162
  store i8 %160, ptr addrspace(3) %163, align 1, !tbaa !12
  %164 = add nuw nsw i32 %157, 1
  %165 = icmp slt i32 %164, %24
  br i1 %165, label %156, label %166

166:                                              ; preds = %156, %150, %143, %140, %130
  %167 = add nuw nsw i32 %120, 1
  %168 = icmp slt i32 %167, %22
  br i1 %168, label %119, label %116

169:                                              ; preds = %17
  %170 = shl nsw i32 %20, 3
  %171 = mul nsw i32 %24, %170
  %172 = icmp sgt i32 %171, 0
  br i1 %172, label %173, label %178

173:                                              ; preds = %169
  %174 = getelementptr inbounds nuw i8, ptr addrspace(1) %0, i64 28
  %175 = load i32, ptr addrspace(1) %174, align 4, !tbaa !26
  %176 = sub nsw i32 %2, %175
  %177 = sdiv i32 %176, %171
  br label %178

178:                                              ; preds = %173, %169
  %179 = phi i32 [ %177, %173 ], [ 0, %169 ]
  %180 = tail call i32 @llvm.smax.i32(i32 %179, i32 0)
  %181 = shl nsw i32 %180, 3
  %182 = icmp eq i32 %3, 0
  %183 = select i1 %182, i32 %181, i32 %3
  %184 = icmp sgt i32 %20, 0
  br i1 %184, label %185, label %220

185:                                              ; preds = %178
  %186 = icmp sgt i32 %24, 0
  br label %187

187:                                              ; preds = %197, %185
  %188 = phi i32 [ 0, %185 ], [ %198, %197 ]
  %189 = shl nsw i32 %188, 3
  %190 = add nsw i32 %188, %4
  %191 = mul nsw i32 %190, %28
  %192 = add i32 %183, %191
  br label %193

193:                                              ; preds = %217, %187
  %194 = phi i32 [ 0, %187 ], [ %218, %217 ]
  %195 = add nsw i32 %194, %183
  %196 = icmp slt i32 %195, %22
  br i1 %196, label %200, label %197

197:                                              ; preds = %217, %193
  %198 = add nuw nsw i32 %188, 1
  %199 = icmp slt i32 %198, %20
  br i1 %199, label %187, label %220

200:                                              ; preds = %193
  %201 = add nuw nsw i32 %194, %189
  %202 = mul nsw i32 %201, %24
  %203 = add i32 %194, %192
  %204 = sext i32 %203 to i64
  %205 = mul nsw i64 %204, %42
  %206 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 %205
  br i1 %186, label %207, label %217

207:                                              ; preds = %207, %200
  %208 = phi i32 [ %215, %207 ], [ 0, %200 ]
  %209 = zext nneg i32 %208 to i64
  %210 = getelementptr inbounds nuw i8, ptr addrspace(1) %206, i64 %209
  %211 = load i8, ptr addrspace(1) %210, align 1, !tbaa !12
  %212 = add nuw nsw i32 %208, %202
  %213 = zext nneg i32 %212 to i64
  %214 = getelementptr inbounds nuw i8, ptr addrspace(3) %1, i64 %213
  store i8 %211, ptr addrspace(3) %214, align 1, !tbaa !12
  %215 = add nuw nsw i32 %208, 1
  %216 = icmp slt i32 %215, %24
  br i1 %216, label %207, label %217

217:                                              ; preds = %207, %200
  %218 = add nuw nsw i32 %194, 1
  %219 = icmp samesign ult i32 %194, 7
  br i1 %219, label %193, label %197

220:                                              ; preds = %197, %178, %116, %83, %59, %47, %15, %12
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

; Function Attrs: convergent norecurse nounwind
define linkonce_odr spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %5, i32 noundef %6, float noundef %7) local_unnamed_addr #7 {
  %9 = icmp ne i64 %2, 0
  %10 = icmp ne i64 %4, 0
  %11 = and i1 %9, %10
  br i1 %11, label %12, label %103

12:                                               ; preds = %8
  %13 = tail call spir_func i64 @_Z19get_local_linear_idv() #10
  %14 = trunc i64 %13 to i32
  %15 = lshr i32 %14, 1
  %16 = and i32 %15, 48
  %17 = shl i32 %5, 2
  %18 = and i32 %17, 8
  %19 = or disjoint i32 %16, %18
  %20 = lshr i32 %14, 2
  %21 = and i32 %20, 7
  %22 = shl i32 %14, 1
  %23 = and i32 %22, 6
  %24 = and i32 %5, 1
  %25 = or disjoint i32 %23, %24
  %26 = icmp slt i32 %6, 0
  %27 = select i1 %26, float -1.000000e+00, float 1.000000e+00
  %28 = trunc i64 %2 to i32
  %29 = lshr i32 %28, 12
  %30 = and i32 %29, 262128
  %31 = lshr i64 %2, 28
  %32 = trunc i64 %31 to i32
  %33 = and i32 %32, 262128
  %34 = lshr i64 %2, 62
  %35 = trunc nuw nsw i64 %34 to i32
  %36 = icmp eq i32 %35, 0
  %37 = add nuw nsw i32 %35, 31
  %38 = and i32 %37, 31
  %39 = lshr i32 128, %38
  %40 = select i1 %36, i32 16, i32 %39
  %41 = lshr exact i32 %19, 3
  %42 = mul nuw nsw i32 %41, %33
  %43 = mul nuw nsw i32 %21, %40
  %44 = add i32 %43, %1
  %45 = add i32 %44, %42
  %46 = addrspacecast ptr addrspace(3) %0 to ptr addrspace(4)
  %47 = trunc i64 %4 to i32
  %48 = lshr i32 %47, 12
  %49 = and i32 %48, 262128
  %50 = lshr i64 %4, 28
  %51 = trunc i64 %50 to i32
  %52 = and i32 %51, 262128
  %53 = lshr i64 %4, 62
  %54 = trunc nuw nsw i64 %53 to i32
  %55 = icmp eq i32 %54, 0
  %56 = add nuw nsw i32 %54, 31
  %57 = and i32 %56, 31
  %58 = lshr i32 128, %57
  %59 = select i1 %55, i32 16, i32 %58
  %60 = ashr i32 %5, 2
  %61 = mul nsw i32 %52, %60
  %62 = mul nuw nsw i32 %25, %59
  %63 = add i32 %61, %3
  %64 = add i32 %63, %62
  %65 = sub nuw nsw i32 4, %35
  %66 = shl nsw i32 -1, %65
  %67 = xor i32 %66, -1
  %68 = sub nuw nsw i32 4, %54
  %69 = shl nsw i32 -1, %68
  %70 = xor i32 %69, -1
  br label %71

71:                                               ; preds = %71, %12
  %72 = phi float [ %7, %12 ], [ %100, %71 ]
  %73 = phi i32 [ 0, %12 ], [ %101, %71 ]
  %74 = lshr i32 %73, 3
  %75 = mul nuw nsw i32 %74, %30
  %76 = shl nuw nsw i32 %73, 1
  %77 = and i32 %76, 14
  %78 = add i32 %45, %77
  %79 = add i32 %78, %75
  %80 = lshr i32 %79, 8
  %81 = and i32 %80, %67
  %82 = shl nuw nsw i32 %81, 5
  %83 = select i1 %36, i32 0, i32 %82
  %84 = xor i32 %79, %83
  %85 = ashr i32 %84, 1
  %86 = sext i32 %85 to i64
  %87 = tail call spir_func float @_Z10vload_halfmPU3AS4KDh(i64 noundef %86, ptr addrspace(4) noundef %46) #12
  %88 = mul nuw nsw i32 %74, %49
  %89 = add i32 %64, %77
  %90 = add i32 %89, %88
  %91 = lshr i32 %90, 8
  %92 = and i32 %91, %70
  %93 = shl nuw nsw i32 %92, 5
  %94 = select i1 %55, i32 0, i32 %93
  %95 = xor i32 %90, %94
  %96 = ashr i32 %95, 1
  %97 = sext i32 %96 to i64
  %98 = tail call spir_func float @_Z10vload_halfmPU3AS4KDh(i64 noundef %97, ptr addrspace(4) noundef %46) #12
  %99 = fmul float %87, %98
  %100 = tail call float @llvm.fmuladd.f32(float %27, float %99, float %72)
  %101 = add nuw nsw i32 %73, 1
  %102 = icmp samesign ult i32 %73, 15
  br i1 %102, label %71, label %103

103:                                              ; preds = %71, %8
  %104 = phi float [ %7, %8 ], [ %100, %71 ]
  ret float %104
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i64 @_Z19get_local_linear_idv() local_unnamed_addr #1

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(read)
declare dso_local spir_func float @_Z10vload_halfmPU3AS4KDh(i64 noundef, ptr addrspace(4) noundef) local_unnamed_addr #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #4

; Function Attrs: convergent norecurse nounwind
define linkonce_odr spir_func noundef float @__zlift_atomic_fadd_global(ptr addrspace(1) noundef %0, float noundef %1) local_unnamed_addr #7 {
  %3 = load volatile i32, ptr addrspace(1) %0, align 4, !tbaa !5
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %4 ]
  %6 = bitcast i32 %5 to float
  %7 = fadd float %1, %6
  %8 = bitcast float %7 to i32
  %9 = tail call spir_func i32 @_Z14atomic_cmpxchgPU3AS1Vjjj(ptr addrspace(1) noundef %0, i32 noundef %5, i32 noundef %8) #10
  %10 = icmp eq i32 %9, %5
  br i1 %10, label %11, label %4

11:                                               ; preds = %4
  ret float %6
}

; Function Attrs: convergent norecurse nounwind
define linkonce_odr spir_func <4 x i32> @__zlift_ldmatrix_x4_mt88_fp8(ptr addrspace(3) nocapture noundef readonly %0) local_unnamed_addr #7 {
  %2 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %3 = load i32, ptr addrspace(3) %0, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 4
  %5 = load i32, ptr addrspace(3) %4, align 4, !tbaa !5
  %6 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 8
  %7 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %8 = getelementptr inbounds nuw i8, ptr addrspace(3) %0, i64 12
  %9 = load i32, ptr addrspace(3) %8, align 4, !tbaa !5
  %10 = lshr i32 %2, 2
  %11 = shl i32 %2, 2
  %12 = and i32 %11, 12
  %13 = and i32 %10, 1073741808
  %14 = or disjoint i32 %12, %13
  %15 = and i32 %10, 15
  %16 = lshr i32 %15, 2
  %17 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %14) #10
  %18 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %14) #10
  %19 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %14) #10
  %20 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %14) #10
  switch i32 %16, label %22 [
    i32 0, label %25
    i32 1, label %21
  ]

21:                                               ; preds = %1
  br label %25

22:                                               ; preds = %1
  %23 = icmp eq i32 %16, 2
  %24 = select i1 %23, i32 %19, i32 %20
  br label %25

25:                                               ; preds = %22, %21, %1
  %26 = phi i32 [ %18, %21 ], [ %24, %22 ], [ %17, %1 ]
  %27 = add nuw nsw i32 %10, 8
  %28 = and i32 %27, 2147483632
  %29 = or disjoint i32 %12, %28
  %30 = and i32 %27, 15
  %31 = lshr i32 %30, 2
  %32 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %29) #10
  %33 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %29) #10
  %34 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %29) #10
  %35 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %29) #10
  switch i32 %31, label %37 [
    i32 0, label %40
    i32 1, label %36
  ]

36:                                               ; preds = %25
  br label %40

37:                                               ; preds = %25
  %38 = icmp eq i32 %31, 2
  %39 = select i1 %38, i32 %34, i32 %35
  br label %40

40:                                               ; preds = %37, %36, %25
  %41 = phi i32 [ %33, %36 ], [ %39, %37 ], [ %32, %25 ]
  %42 = or disjoint i32 %12, 1
  %43 = add nuw nsw i32 %10, 16
  %44 = or disjoint i32 %42, %13
  %45 = and i32 %10, 15
  %46 = lshr i32 %45, 2
  %47 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %44) #10
  %48 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %44) #10
  %49 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %44) #10
  %50 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %44) #10
  switch i32 %46, label %52 [
    i32 0, label %55
    i32 1, label %51
  ]

51:                                               ; preds = %40
  br label %55

52:                                               ; preds = %40
  %53 = icmp eq i32 %46, 2
  %54 = select i1 %53, i32 %49, i32 %50
  br label %55

55:                                               ; preds = %52, %51, %40
  %56 = phi i32 [ %48, %51 ], [ %54, %52 ], [ %47, %40 ]
  %57 = or disjoint i32 %42, %28
  %58 = and i32 %10, 15
  %59 = lshr i32 %58, 2
  %60 = xor i32 %59, 2
  %61 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %57) #10
  %62 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %57) #10
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %57) #10
  %64 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %57) #10
  switch i32 %60, label %66 [
    i32 0, label %69
    i32 1, label %65
  ]

65:                                               ; preds = %55
  br label %69

66:                                               ; preds = %55
  %67 = icmp samesign ult i32 %58, 4
  %68 = select i1 %67, i32 %63, i32 %64
  br label %69

69:                                               ; preds = %66, %65, %55
  %70 = phi i32 [ %62, %65 ], [ %68, %66 ], [ %61, %55 ]
  %71 = or disjoint i32 %12, 2
  %72 = or disjoint i32 %71, %13
  %73 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %72) #10
  %74 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %72) #10
  %75 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %72) #10
  %76 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %72) #10
  switch i32 %16, label %78 [
    i32 0, label %81
    i32 1, label %77
  ]

77:                                               ; preds = %69
  br label %81

78:                                               ; preds = %69
  %79 = icmp eq i32 %16, 2
  %80 = select i1 %79, i32 %75, i32 %76
  br label %81

81:                                               ; preds = %78, %77, %69
  %82 = phi i32 [ %74, %77 ], [ %80, %78 ], [ %73, %69 ]
  %83 = or disjoint i32 %71, %28
  %84 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %83) #10
  %85 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %83) #10
  %86 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %83) #10
  %87 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %83) #10
  switch i32 %31, label %89 [
    i32 0, label %92
    i32 1, label %88
  ]

88:                                               ; preds = %81
  br label %92

89:                                               ; preds = %81
  %90 = icmp eq i32 %31, 2
  %91 = select i1 %90, i32 %86, i32 %87
  br label %92

92:                                               ; preds = %89, %88, %81
  %93 = phi i32 [ %85, %88 ], [ %91, %89 ], [ %84, %81 ]
  %94 = or disjoint i32 %12, 3
  %95 = or disjoint i32 %94, %13
  %96 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %95) #10
  %97 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %95) #10
  %98 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %95) #10
  %99 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %95) #10
  switch i32 %46, label %101 [
    i32 0, label %104
    i32 1, label %100
  ]

100:                                              ; preds = %92
  br label %104

101:                                              ; preds = %92
  %102 = icmp eq i32 %46, 2
  %103 = select i1 %102, i32 %98, i32 %99
  br label %104

104:                                              ; preds = %101, %100, %92
  %105 = phi i32 [ %97, %100 ], [ %103, %101 ], [ %96, %92 ]
  %106 = or disjoint i32 %94, %28
  %107 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %106) #10
  %108 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %106) #10
  %109 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %106) #10
  %110 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %106) #10
  switch i32 %60, label %112 [
    i32 0, label %115
    i32 1, label %111
  ]

111:                                              ; preds = %104
  br label %115

112:                                              ; preds = %104
  %113 = icmp samesign ult i32 %58, 4
  %114 = select i1 %113, i32 %109, i32 %110
  br label %115

115:                                              ; preds = %112, %111, %104
  %116 = phi i32 [ %108, %111 ], [ %114, %112 ], [ %107, %104 ]
  %117 = and i32 %43, 2147483632
  %118 = or disjoint i32 %12, %117
  %119 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %118) #10
  %120 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %118) #10
  %121 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %118) #10
  %122 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %118) #10
  switch i32 %16, label %124 [
    i32 0, label %127
    i32 1, label %123
  ]

123:                                              ; preds = %115
  br label %127

124:                                              ; preds = %115
  %125 = icmp eq i32 %16, 2
  %126 = select i1 %125, i32 %121, i32 %122
  br label %127

127:                                              ; preds = %124, %123, %115
  %128 = phi i32 [ %120, %123 ], [ %126, %124 ], [ %119, %115 ]
  %129 = add nuw nsw i32 %10, 24
  %130 = and i32 %129, 2147483632
  %131 = or disjoint i32 %12, %130
  %132 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %131) #10
  %133 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %131) #10
  %134 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %131) #10
  %135 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %131) #10
  switch i32 %31, label %137 [
    i32 0, label %140
    i32 1, label %136
  ]

136:                                              ; preds = %127
  br label %140

137:                                              ; preds = %127
  %138 = icmp eq i32 %31, 2
  %139 = select i1 %138, i32 %134, i32 %135
  br label %140

140:                                              ; preds = %137, %136, %127
  %141 = phi i32 [ %133, %136 ], [ %139, %137 ], [ %132, %127 ]
  %142 = or disjoint i32 %42, %117
  %143 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %142) #10
  %144 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %142) #10
  %145 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %142) #10
  %146 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %142) #10
  switch i32 %46, label %148 [
    i32 0, label %151
    i32 1, label %147
  ]

147:                                              ; preds = %140
  br label %151

148:                                              ; preds = %140
  %149 = icmp eq i32 %46, 2
  %150 = select i1 %149, i32 %145, i32 %146
  br label %151

151:                                              ; preds = %148, %147, %140
  %152 = phi i32 [ %144, %147 ], [ %150, %148 ], [ %143, %140 ]
  %153 = or disjoint i32 %42, %130
  %154 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %153) #10
  %155 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %153) #10
  %156 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %153) #10
  %157 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %153) #10
  switch i32 %60, label %159 [
    i32 0, label %162
    i32 1, label %158
  ]

158:                                              ; preds = %151
  br label %162

159:                                              ; preds = %151
  %160 = icmp samesign ult i32 %58, 4
  %161 = select i1 %160, i32 %156, i32 %157
  br label %162

162:                                              ; preds = %159, %158, %151
  %163 = phi i32 [ %155, %158 ], [ %161, %159 ], [ %154, %151 ]
  %164 = or disjoint i32 %71, %117
  %165 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %164) #10
  %166 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %164) #10
  %167 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %164) #10
  %168 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %164) #10
  switch i32 %16, label %170 [
    i32 0, label %173
    i32 1, label %169
  ]

169:                                              ; preds = %162
  br label %173

170:                                              ; preds = %162
  %171 = icmp eq i32 %16, 2
  %172 = select i1 %171, i32 %167, i32 %168
  br label %173

173:                                              ; preds = %170, %169, %162
  %174 = phi i32 [ %166, %169 ], [ %172, %170 ], [ %165, %162 ]
  %175 = or disjoint i32 %71, %130
  %176 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %175) #10
  %177 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %175) #10
  %178 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %175) #10
  %179 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %175) #10
  switch i32 %31, label %181 [
    i32 0, label %184
    i32 1, label %180
  ]

180:                                              ; preds = %173
  br label %184

181:                                              ; preds = %173
  %182 = icmp eq i32 %31, 2
  %183 = select i1 %182, i32 %178, i32 %179
  br label %184

184:                                              ; preds = %181, %180, %173
  %185 = phi i32 [ %177, %180 ], [ %183, %181 ], [ %176, %173 ]
  %186 = or disjoint i32 %94, %117
  %187 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %186) #10
  %188 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %186) #10
  %189 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %186) #10
  %190 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %186) #10
  switch i32 %46, label %192 [
    i32 0, label %195
    i32 1, label %191
  ]

191:                                              ; preds = %184
  br label %195

192:                                              ; preds = %184
  %193 = icmp eq i32 %46, 2
  %194 = select i1 %193, i32 %189, i32 %190
  br label %195

195:                                              ; preds = %192, %191, %184
  %196 = phi i32 [ %188, %191 ], [ %194, %192 ], [ %187, %184 ]
  %197 = or disjoint i32 %94, %130
  %198 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 1073741856) %197) #10
  %199 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 1073741856) %197) #10
  %200 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 1073741856) %197) #10
  %201 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef range(i32 0, 1073741856) %197) #10
  switch i32 %60, label %203 [
    i32 0, label %206
    i32 1, label %202
  ]

202:                                              ; preds = %195
  br label %206

203:                                              ; preds = %195
  %204 = icmp samesign ult i32 %58, 4
  %205 = select i1 %204, i32 %200, i32 %201
  br label %206

206:                                              ; preds = %203, %202, %195
  %207 = phi i32 [ %199, %202 ], [ %205, %203 ], [ %198, %195 ]
  %208 = shl nuw nsw i32 %45, 3
  %209 = and i32 %208, 24
  %210 = shl nuw nsw i32 %30, 3
  %211 = and i32 %210, 24
  %212 = shl nuw nsw i32 %15, 3
  %213 = and i32 %212, 24
  %214 = shl nuw nsw i32 %58, 3
  %215 = and i32 %214, 24
  %216 = insertelement <4 x i32> poison, i32 %56, i64 0
  %217 = insertelement <4 x i32> %216, i32 %105, i64 1
  %218 = insertelement <4 x i32> %217, i32 %152, i64 2
  %219 = insertelement <4 x i32> %218, i32 %196, i64 3
  %220 = insertelement <4 x i32> poison, i32 %209, i64 0
  %221 = shufflevector <4 x i32> %220, <4 x i32> poison, <4 x i32> zeroinitializer
  %222 = lshr <4 x i32> %219, %221
  %223 = shl <4 x i32> %222, splat (i32 16)
  %224 = and <4 x i32> %223, splat (i32 16711680)
  %225 = insertelement <4 x i32> poison, i32 %41, i64 0
  %226 = insertelement <4 x i32> %225, i32 %93, i64 1
  %227 = insertelement <4 x i32> %226, i32 %141, i64 2
  %228 = insertelement <4 x i32> %227, i32 %185, i64 3
  %229 = insertelement <4 x i32> poison, i32 %211, i64 0
  %230 = shufflevector <4 x i32> %229, <4 x i32> poison, <4 x i32> zeroinitializer
  %231 = lshr <4 x i32> %228, %230
  %232 = shl <4 x i32> %231, splat (i32 8)
  %233 = and <4 x i32> %232, splat (i32 65280)
  %234 = insertelement <4 x i32> poison, i32 %26, i64 0
  %235 = insertelement <4 x i32> %234, i32 %82, i64 1
  %236 = insertelement <4 x i32> %235, i32 %128, i64 2
  %237 = insertelement <4 x i32> %236, i32 %174, i64 3
  %238 = insertelement <4 x i32> poison, i32 %213, i64 0
  %239 = shufflevector <4 x i32> %238, <4 x i32> poison, <4 x i32> zeroinitializer
  %240 = lshr <4 x i32> %237, %239
  %241 = and <4 x i32> %240, splat (i32 255)
  %242 = or disjoint <4 x i32> %233, %241
  %243 = or disjoint <4 x i32> %224, %242
  %244 = insertelement <4 x i32> poison, i32 %70, i64 0
  %245 = insertelement <4 x i32> %244, i32 %116, i64 1
  %246 = insertelement <4 x i32> %245, i32 %163, i64 2
  %247 = insertelement <4 x i32> %246, i32 %207, i64 3
  %248 = insertelement <4 x i32> poison, i32 %215, i64 0
  %249 = shufflevector <4 x i32> %248, <4 x i32> poison, <4 x i32> zeroinitializer
  %250 = lshr <4 x i32> %247, %249
  %251 = shl <4 x i32> %250, splat (i32 24)
  %252 = or disjoint <4 x i32> %251, %243
  ret <4 x i32> %252
}

; Function Attrs: convergent norecurse nounwind
define linkonce_odr spir_func <4 x i32> @__zlift_mma_sp_m16n8k64_s32_s8(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6, i32 noundef %7, <4 x i32> noundef %8, i32 noundef %9) local_unnamed_addr #7 {
  %11 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %12 = extractelement <4 x i32> %8, i64 0
  %13 = extractelement <4 x i32> %8, i64 1
  %14 = extractelement <4 x i32> %8, i64 2
  %15 = extractelement <4 x i32> %8, i64 3
  %16 = lshr i32 %11, 3
  %17 = shl i32 %11, 1
  %18 = and i32 %17, 6
  %19 = and i32 %11, 28
  %20 = lshr i32 %11, 3
  %21 = and i32 %20, 4
  %22 = shl nuw nsw i32 %18, 2
  br label %202

23:                                               ; preds = %247
  %24 = shl nuw nsw i32 %18, 2
  %25 = or disjoint i32 %24, 4
  br label %26

26:                                               ; preds = %71, %23
  %27 = phi i32 [ %13, %23 ], [ %79, %71 ]
  %28 = phi i32 [ 0, %23 ], [ %80, %71 ]
  %29 = lshr i32 %28, 2
  %30 = and i32 %29, 3
  %31 = or disjoint i32 %30, %19
  %32 = and i32 %28, 3
  %33 = lshr i32 %28, 1
  %34 = and i32 %33, 8
  %35 = or disjoint i32 %32, %34
  %36 = or disjoint i32 %35, %21
  %37 = lshr i32 %36, 2
  %38 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef range(i32 0, 32) %31) #10
  %39 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef range(i32 0, 32) %31) #10
  %40 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef range(i32 0, 32) %31) #10
  %41 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %31) #10
  switch i32 %37, label %43 [
    i32 0, label %46
    i32 1, label %42
  ]

42:                                               ; preds = %26
  br label %46

43:                                               ; preds = %26
  %44 = icmp eq i32 %37, 2
  %45 = select i1 %44, i32 %40, i32 %41
  br label %46

46:                                               ; preds = %43, %42, %26
  %47 = phi i32 [ %39, %42 ], [ %45, %43 ], [ %38, %26 ]
  %48 = shl nuw nsw i32 %28, 3
  %49 = and i32 %48, 24
  %50 = ashr i32 %47, %49
  %51 = shl i32 %50, 24
  %52 = ashr exact i32 %51, 24
  %53 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %31) #10
  %54 = shl nuw nsw i32 %36, 1
  %55 = and i32 %54, 28
  %56 = lshr i32 %53, %55
  %57 = shl nuw nsw i32 %28, 1
  %58 = and i32 %57, 2
  %59 = lshr i32 %56, %58
  %60 = and i32 %33, 3
  %61 = or disjoint i32 %60, %25
  %62 = lshr i32 %28, 3
  %63 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef range(i32 0, 32) %61) #10
  %64 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %61) #10
  %65 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %6, i32 noundef range(i32 0, 32) %61) #10
  %66 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %61) #10
  switch i32 %62, label %68 [
    i32 0, label %71
    i32 1, label %67
  ]

67:                                               ; preds = %46
  br label %71

68:                                               ; preds = %46
  %69 = icmp eq i32 %62, 2
  %70 = select i1 %69, i32 %65, i32 %66
  br label %71

71:                                               ; preds = %68, %67, %46
  %72 = phi i32 [ %64, %67 ], [ %70, %68 ], [ %63, %46 ]
  %73 = shl i32 %59, 3
  %74 = and i32 %73, 24
  %75 = ashr i32 %72, %74
  %76 = shl i32 %75, 24
  %77 = ashr exact i32 %76, 24
  %78 = mul nsw i32 %77, %52
  %79 = add nsw i32 %78, %27
  %80 = add nuw nsw i32 %28, 1
  %81 = icmp samesign ult i32 %28, 31
  br i1 %81, label %26, label %82

82:                                               ; preds = %71
  %83 = and i32 %16, 4
  %84 = xor i32 %83, 4
  br label %85

85:                                               ; preds = %130, %82
  %86 = phi i32 [ %14, %82 ], [ %138, %130 ]
  %87 = phi i32 [ 0, %82 ], [ %139, %130 ]
  %88 = lshr i32 %87, 2
  %89 = and i32 %88, 3
  %90 = or disjoint i32 %89, %19
  %91 = and i32 %87, 3
  %92 = lshr i32 %87, 1
  %93 = and i32 %92, 8
  %94 = or disjoint i32 %91, %93
  %95 = or disjoint i32 %94, %84
  %96 = lshr i32 %95, 2
  %97 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef range(i32 0, 32) %90) #10
  %98 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef range(i32 0, 32) %90) #10
  %99 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef range(i32 0, 32) %90) #10
  %100 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %90) #10
  switch i32 %96, label %102 [
    i32 0, label %105
    i32 1, label %101
  ]

101:                                              ; preds = %85
  br label %105

102:                                              ; preds = %85
  %103 = icmp eq i32 %96, 2
  %104 = select i1 %103, i32 %99, i32 %100
  br label %105

105:                                              ; preds = %102, %101, %85
  %106 = phi i32 [ %98, %101 ], [ %104, %102 ], [ %97, %85 ]
  %107 = shl nuw nsw i32 %87, 3
  %108 = and i32 %107, 24
  %109 = ashr i32 %106, %108
  %110 = shl i32 %109, 24
  %111 = ashr exact i32 %110, 24
  %112 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %90) #10
  %113 = shl nuw nsw i32 %95, 1
  %114 = and i32 %113, 28
  %115 = lshr i32 %112, %114
  %116 = shl nuw nsw i32 %87, 1
  %117 = and i32 %116, 2
  %118 = lshr i32 %115, %117
  %119 = and i32 %92, 3
  %120 = or disjoint i32 %119, %22
  %121 = lshr i32 %87, 3
  %122 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef range(i32 0, 32) %120) #10
  %123 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %120) #10
  %124 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %6, i32 noundef range(i32 0, 32) %120) #10
  %125 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %120) #10
  switch i32 %121, label %127 [
    i32 0, label %130
    i32 1, label %126
  ]

126:                                              ; preds = %105
  br label %130

127:                                              ; preds = %105
  %128 = icmp eq i32 %121, 2
  %129 = select i1 %128, i32 %124, i32 %125
  br label %130

130:                                              ; preds = %127, %126, %105
  %131 = phi i32 [ %123, %126 ], [ %129, %127 ], [ %122, %105 ]
  %132 = shl i32 %118, 3
  %133 = and i32 %132, 24
  %134 = ashr i32 %131, %133
  %135 = shl i32 %134, 24
  %136 = ashr exact i32 %135, 24
  %137 = mul nsw i32 %136, %111
  %138 = add nsw i32 %137, %86
  %139 = add nuw nsw i32 %87, 1
  %140 = icmp samesign ult i32 %87, 31
  br i1 %140, label %85, label %141

141:                                              ; preds = %186, %130
  %142 = phi i32 [ %194, %186 ], [ %15, %130 ]
  %143 = phi i32 [ %195, %186 ], [ 0, %130 ]
  %144 = lshr i32 %143, 2
  %145 = and i32 %144, 3
  %146 = or disjoint i32 %145, %19
  %147 = and i32 %143, 3
  %148 = lshr i32 %143, 1
  %149 = and i32 %148, 8
  %150 = or disjoint i32 %147, %149
  %151 = or disjoint i32 %150, %84
  %152 = lshr i32 %151, 2
  %153 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef range(i32 0, 32) %146) #10
  %154 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef range(i32 0, 32) %146) #10
  %155 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef range(i32 0, 32) %146) #10
  %156 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %146) #10
  switch i32 %152, label %158 [
    i32 0, label %161
    i32 1, label %157
  ]

157:                                              ; preds = %141
  br label %161

158:                                              ; preds = %141
  %159 = icmp eq i32 %152, 2
  %160 = select i1 %159, i32 %155, i32 %156
  br label %161

161:                                              ; preds = %158, %157, %141
  %162 = phi i32 [ %154, %157 ], [ %160, %158 ], [ %153, %141 ]
  %163 = shl nuw nsw i32 %143, 3
  %164 = and i32 %163, 24
  %165 = ashr i32 %162, %164
  %166 = shl i32 %165, 24
  %167 = ashr exact i32 %166, 24
  %168 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %146) #10
  %169 = shl nuw nsw i32 %151, 1
  %170 = and i32 %169, 28
  %171 = lshr i32 %168, %170
  %172 = shl nuw nsw i32 %143, 1
  %173 = and i32 %172, 2
  %174 = lshr i32 %171, %173
  %175 = and i32 %148, 3
  %176 = or disjoint i32 %175, %25
  %177 = lshr i32 %143, 3
  %178 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef range(i32 0, 32) %176) #10
  %179 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %176) #10
  %180 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %6, i32 noundef range(i32 0, 32) %176) #10
  %181 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %176) #10
  switch i32 %177, label %183 [
    i32 0, label %186
    i32 1, label %182
  ]

182:                                              ; preds = %161
  br label %186

183:                                              ; preds = %161
  %184 = icmp eq i32 %177, 2
  %185 = select i1 %184, i32 %180, i32 %181
  br label %186

186:                                              ; preds = %183, %182, %161
  %187 = phi i32 [ %179, %182 ], [ %185, %183 ], [ %178, %161 ]
  %188 = shl i32 %174, 3
  %189 = and i32 %188, 24
  %190 = ashr i32 %187, %189
  %191 = shl i32 %190, 24
  %192 = ashr exact i32 %191, 24
  %193 = mul nsw i32 %192, %167
  %194 = add nsw i32 %193, %142
  %195 = add nuw nsw i32 %143, 1
  %196 = icmp samesign ult i32 %143, 31
  br i1 %196, label %141, label %197

197:                                              ; preds = %186
  %198 = insertelement <4 x i32> poison, i32 %255, i64 0
  %199 = insertelement <4 x i32> %198, i32 %79, i64 1
  %200 = insertelement <4 x i32> %199, i32 %138, i64 2
  %201 = insertelement <4 x i32> %200, i32 %194, i64 3
  ret <4 x i32> %201

202:                                              ; preds = %247, %10
  %203 = phi i32 [ %12, %10 ], [ %255, %247 ]
  %204 = phi i32 [ 0, %10 ], [ %256, %247 ]
  %205 = lshr i32 %204, 2
  %206 = and i32 %205, 3
  %207 = or disjoint i32 %206, %19
  %208 = and i32 %204, 3
  %209 = lshr i32 %204, 1
  %210 = and i32 %209, 8
  %211 = or disjoint i32 %208, %210
  %212 = or disjoint i32 %211, %21
  %213 = lshr i32 %212, 2
  %214 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %0, i32 noundef range(i32 0, 32) %207) #10
  %215 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %1, i32 noundef range(i32 0, 32) %207) #10
  %216 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %2, i32 noundef range(i32 0, 32) %207) #10
  %217 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %3, i32 noundef range(i32 0, 32) %207) #10
  switch i32 %213, label %219 [
    i32 0, label %222
    i32 1, label %218
  ]

218:                                              ; preds = %202
  br label %222

219:                                              ; preds = %202
  %220 = icmp eq i32 %213, 2
  %221 = select i1 %220, i32 %216, i32 %217
  br label %222

222:                                              ; preds = %219, %218, %202
  %223 = phi i32 [ %215, %218 ], [ %221, %219 ], [ %214, %202 ]
  %224 = shl nuw nsw i32 %204, 3
  %225 = and i32 %224, 24
  %226 = ashr i32 %223, %225
  %227 = shl i32 %226, 24
  %228 = ashr exact i32 %227, 24
  %229 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %9, i32 noundef %207) #10
  %230 = shl nuw nsw i32 %212, 1
  %231 = and i32 %230, 28
  %232 = lshr i32 %229, %231
  %233 = shl nuw nsw i32 %204, 1
  %234 = and i32 %233, 2
  %235 = lshr i32 %232, %234
  %236 = and i32 %209, 3
  %237 = or disjoint i32 %236, %22
  %238 = lshr i32 %204, 3
  %239 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %4, i32 noundef range(i32 0, 32) %237) #10
  %240 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %5, i32 noundef range(i32 0, 32) %237) #10
  %241 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %6, i32 noundef range(i32 0, 32) %237) #10
  %242 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %7, i32 noundef range(i32 0, 32) %237) #10
  switch i32 %238, label %244 [
    i32 0, label %247
    i32 1, label %243
  ]

243:                                              ; preds = %222
  br label %247

244:                                              ; preds = %222
  %245 = icmp eq i32 %238, 2
  %246 = select i1 %245, i32 %241, i32 %242
  br label %247

247:                                              ; preds = %244, %243, %222
  %248 = phi i32 [ %240, %243 ], [ %246, %244 ], [ %239, %222 ]
  %249 = shl i32 %235, 3
  %250 = and i32 %249, 24
  %251 = ashr i32 %248, %250
  %252 = shl i32 %251, 24
  %253 = ashr exact i32 %252, 24
  %254 = mul nsw i32 %253, %228
  %255 = add nsw i32 %254, %203
  %256 = add nuw nsw i32 %204, 1
  %257 = icmp samesign ult i32 %204, 31
  br i1 %257, label %202, label %23
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zlift_wgmma_tile8_mem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %5, i32 noundef %6, <8 x float> noundef %7, i32 noundef %8) local_unnamed_addr #0 {
  %10 = icmp ne i64 %2, 0
  %11 = icmp ne i64 %4, 0
  %12 = and i1 %10, %11
  br i1 %12, label %13, label %506

13:                                               ; preds = %9
  %14 = tail call spir_func i32 @_Z16get_sub_group_idv() #10
  %15 = icmp ugt i32 %14, 7
  br i1 %15, label %16, label %49

16:                                               ; preds = %13
  %17 = extractelement <8 x float> %7, i64 0
  %18 = extractelement <8 x float> %7, i64 1
  %19 = extractelement <8 x float> %7, i64 2
  %20 = extractelement <8 x float> %7, i64 3
  %21 = extractelement <8 x float> %7, i64 4
  %22 = extractelement <8 x float> %7, i64 5
  %23 = extractelement <8 x float> %7, i64 6
  %24 = extractelement <8 x float> %7, i64 7
  %25 = shl nsw i32 %5, 3
  %26 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %25, i32 noundef %6, float noundef %17) #10
  %27 = or disjoint i32 %25, 1
  %28 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %27, i32 noundef %6, float noundef %18) #10
  %29 = or disjoint i32 %25, 2
  %30 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %29, i32 noundef %6, float noundef %19) #10
  %31 = or disjoint i32 %25, 3
  %32 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %31, i32 noundef %6, float noundef %20) #10
  %33 = or disjoint i32 %25, 4
  %34 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %33, i32 noundef %6, float noundef %21) #10
  %35 = or disjoint i32 %25, 5
  %36 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %35, i32 noundef %6, float noundef %22) #10
  %37 = or disjoint i32 %25, 6
  %38 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %37, i32 noundef %6, float noundef %23) #10
  %39 = or disjoint i32 %25, 7
  %40 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %39, i32 noundef %6, float noundef %24) #10
  %41 = insertelement <8 x float> poison, float %26, i64 0
  %42 = insertelement <8 x float> %41, float %28, i64 1
  %43 = insertelement <8 x float> %42, float %30, i64 2
  %44 = insertelement <8 x float> %43, float %32, i64 3
  %45 = insertelement <8 x float> %44, float %34, i64 4
  %46 = insertelement <8 x float> %45, float %36, i64 5
  %47 = insertelement <8 x float> %46, float %38, i64 6
  %48 = insertelement <8 x float> %47, float %40, i64 7
  br label %506

49:                                               ; preds = %13
  %50 = tail call spir_func i64 @_Z19get_local_linear_idv() #10
  %51 = trunc i64 %50 to i32
  %52 = and i32 %51, 31
  %53 = lshr i32 %52, 4
  %54 = and i32 %51, 15
  %55 = shl nsw i32 %5, 4
  %56 = icmp slt i32 %6, 0
  %57 = select i1 %56, float -1.000000e+00, float 1.000000e+00
  %58 = or disjoint i32 %54, %55
  %59 = trunc i64 %4 to i32
  %60 = lshr i32 %59, 12
  %61 = and i32 %60, 262128
  %62 = lshr i64 %4, 28
  %63 = trunc i64 %62 to i32
  %64 = and i32 %63, 262128
  %65 = lshr i64 %4, 62
  %66 = trunc nuw nsw i64 %65 to i32
  %67 = icmp eq i32 %66, 0
  %68 = add nuw nsw i32 %66, 31
  %69 = and i32 %68, 31
  %70 = lshr i32 128, %69
  %71 = select i1 %67, i32 16, i32 %70
  %72 = ashr i32 %58, 3
  %73 = mul nsw i32 %72, %64
  %74 = mul nuw nsw i32 %53, %61
  %75 = and i32 %51, 7
  %76 = mul nuw nsw i32 %75, %71
  %77 = add i32 %3, 2
  %78 = add i32 %77, %76
  %79 = add i32 %78, %74
  %80 = add i32 %79, %73
  br i1 %67, label %89, label %81

81:                                               ; preds = %49
  %82 = sub nuw nsw i32 4, %66
  %83 = lshr i32 %80, 8
  %84 = shl nsw i32 -1, %82
  %85 = xor i32 %84, -1
  %86 = and i32 %83, %85
  %87 = shl nuw nsw i32 %86, 5
  %88 = xor i32 %87, %80
  br label %89

89:                                               ; preds = %81, %49
  %90 = phi i32 [ %88, %81 ], [ %80, %49 ]
  %91 = ashr i32 %90, 1
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %92
  %94 = load i16, ptr addrspace(3) %93, align 2, !tbaa !27
  %95 = zext i16 %94 to i32
  %96 = shl nuw i32 %95, 16
  %97 = add i32 %76, %3
  %98 = add i32 %97, %74
  %99 = add i32 %98, %73
  br i1 %67, label %108, label %100

100:                                              ; preds = %89
  %101 = sub nuw nsw i32 4, %66
  %102 = lshr i32 %99, 8
  %103 = shl nsw i32 -1, %101
  %104 = xor i32 %103, -1
  %105 = and i32 %102, %104
  %106 = shl nuw nsw i32 %105, 5
  %107 = xor i32 %106, %99
  br label %108

108:                                              ; preds = %100, %89
  %109 = phi i32 [ %107, %100 ], [ %99, %89 ]
  %110 = ashr i32 %109, 1
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %111
  %113 = load i16, ptr addrspace(3) %112, align 2, !tbaa !27
  %114 = zext i16 %113 to i32
  %115 = or disjoint i32 %96, %114
  %116 = insertelement <4 x i32> poison, i32 %115, i64 0
  %117 = add i32 %3, 6
  %118 = add i32 %117, %76
  %119 = add i32 %118, %74
  %120 = add i32 %119, %73
  br i1 %67, label %129, label %121

121:                                              ; preds = %108
  %122 = sub nuw nsw i32 4, %66
  %123 = lshr i32 %120, 8
  %124 = shl nsw i32 -1, %122
  %125 = xor i32 %124, -1
  %126 = and i32 %123, %125
  %127 = shl nuw nsw i32 %126, 5
  %128 = xor i32 %127, %120
  br label %129

129:                                              ; preds = %121, %108
  %130 = phi i32 [ %128, %121 ], [ %120, %108 ]
  %131 = ashr i32 %130, 1
  %132 = sext i32 %131 to i64
  %133 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %132
  %134 = load i16, ptr addrspace(3) %133, align 2, !tbaa !27
  %135 = zext i16 %134 to i32
  %136 = shl nuw i32 %135, 16
  %137 = add i32 %3, 4
  %138 = add i32 %137, %76
  %139 = add i32 %138, %74
  %140 = add i32 %139, %73
  br i1 %67, label %149, label %141

141:                                              ; preds = %129
  %142 = sub nuw nsw i32 4, %66
  %143 = lshr i32 %140, 8
  %144 = shl nsw i32 -1, %142
  %145 = xor i32 %144, -1
  %146 = and i32 %143, %145
  %147 = shl nuw nsw i32 %146, 5
  %148 = xor i32 %147, %140
  br label %149

149:                                              ; preds = %141, %129
  %150 = phi i32 [ %148, %141 ], [ %140, %129 ]
  %151 = ashr i32 %150, 1
  %152 = sext i32 %151 to i64
  %153 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %152
  %154 = load i16, ptr addrspace(3) %153, align 2, !tbaa !27
  %155 = zext i16 %154 to i32
  %156 = or disjoint i32 %136, %155
  %157 = insertelement <4 x i32> %116, i32 %156, i64 1
  %158 = add i32 %3, 10
  %159 = add i32 %158, %76
  %160 = add i32 %159, %74
  %161 = add i32 %160, %73
  br i1 %67, label %170, label %162

162:                                              ; preds = %149
  %163 = sub nuw nsw i32 4, %66
  %164 = lshr i32 %161, 8
  %165 = shl nsw i32 -1, %163
  %166 = xor i32 %165, -1
  %167 = and i32 %164, %166
  %168 = shl nuw nsw i32 %167, 5
  %169 = xor i32 %168, %161
  br label %170

170:                                              ; preds = %162, %149
  %171 = phi i32 [ %169, %162 ], [ %161, %149 ]
  %172 = ashr i32 %171, 1
  %173 = sext i32 %172 to i64
  %174 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %173
  %175 = load i16, ptr addrspace(3) %174, align 2, !tbaa !27
  %176 = zext i16 %175 to i32
  %177 = shl nuw i32 %176, 16
  %178 = add i32 %3, 8
  %179 = add i32 %178, %76
  %180 = add i32 %179, %74
  %181 = add i32 %180, %73
  br i1 %67, label %190, label %182

182:                                              ; preds = %170
  %183 = sub nuw nsw i32 4, %66
  %184 = lshr i32 %181, 8
  %185 = shl nsw i32 -1, %183
  %186 = xor i32 %185, -1
  %187 = and i32 %184, %186
  %188 = shl nuw nsw i32 %187, 5
  %189 = xor i32 %188, %181
  br label %190

190:                                              ; preds = %182, %170
  %191 = phi i32 [ %189, %182 ], [ %181, %170 ]
  %192 = ashr i32 %191, 1
  %193 = sext i32 %192 to i64
  %194 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %193
  %195 = load i16, ptr addrspace(3) %194, align 2, !tbaa !27
  %196 = zext i16 %195 to i32
  %197 = or disjoint i32 %177, %196
  %198 = insertelement <4 x i32> %157, i32 %197, i64 2
  %199 = add i32 %3, 14
  %200 = add i32 %199, %76
  %201 = add i32 %200, %74
  %202 = add i32 %201, %73
  br i1 %67, label %211, label %203

203:                                              ; preds = %190
  %204 = sub nuw nsw i32 4, %66
  %205 = lshr i32 %202, 8
  %206 = shl nsw i32 -1, %204
  %207 = xor i32 %206, -1
  %208 = and i32 %205, %207
  %209 = shl nuw nsw i32 %208, 5
  %210 = xor i32 %209, %202
  br label %211

211:                                              ; preds = %203, %190
  %212 = phi i32 [ %210, %203 ], [ %202, %190 ]
  %213 = ashr i32 %212, 1
  %214 = sext i32 %213 to i64
  %215 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %214
  %216 = load i16, ptr addrspace(3) %215, align 2, !tbaa !27
  %217 = zext i16 %216 to i32
  %218 = shl nuw i32 %217, 16
  %219 = add i32 %3, 12
  %220 = add i32 %219, %76
  %221 = add i32 %220, %74
  %222 = add i32 %221, %73
  br i1 %67, label %231, label %223

223:                                              ; preds = %211
  %224 = sub nuw nsw i32 4, %66
  %225 = lshr i32 %222, 8
  %226 = shl nsw i32 -1, %224
  %227 = xor i32 %226, -1
  %228 = and i32 %225, %227
  %229 = shl nuw nsw i32 %228, 5
  %230 = xor i32 %229, %222
  br label %231

231:                                              ; preds = %223, %211
  %232 = phi i32 [ %230, %223 ], [ %222, %211 ]
  %233 = ashr i32 %232, 1
  %234 = sext i32 %233 to i64
  %235 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %234
  %236 = load i16, ptr addrspace(3) %235, align 2, !tbaa !27
  %237 = zext i16 %236 to i32
  %238 = or disjoint i32 %218, %237
  %239 = insertelement <4 x i32> %198, i32 %238, i64 3
  %240 = and i64 %50, 15
  %241 = getelementptr inbounds nuw [16 x i8], ptr addrspace(2) @ZLIFT_DPAS_K, i64 0, i64 %240
  %242 = load i8, ptr addrspace(2) %241, align 1, !tbaa !12
  %243 = zext i8 %242 to i32
  %244 = lshr i32 %51, 1
  %245 = and i32 %244, 48
  %246 = shl nuw nsw i32 %53, 2
  %247 = or disjoint i32 %246, %245
  %248 = trunc i64 %2 to i32
  %249 = lshr i32 %248, 12
  %250 = and i32 %249, 262128
  %251 = lshr i64 %2, 28
  %252 = trunc i64 %251 to i32
  %253 = and i32 %252, 262128
  %254 = lshr i64 %2, 62
  %255 = trunc nuw nsw i64 %254 to i32
  %256 = icmp eq i32 %255, 0
  %257 = add nuw nsw i32 %255, 31
  %258 = and i32 %257, 31
  %259 = lshr i32 128, %258
  %260 = select i1 %256, i32 16, i32 %259
  %261 = lshr exact i32 %245, 3
  %262 = mul nuw nsw i32 %261, %253
  %263 = lshr i32 %243, 3
  %264 = mul nuw nsw i32 %263, %250
  %265 = mul nuw nsw i32 %246, %260
  %266 = shl nuw nsw i32 %243, 1
  %267 = and i32 %266, 14
  %268 = add i32 %267, %1
  %269 = add i32 %268, %264
  %270 = add i32 %269, %262
  %271 = add i32 %270, %265
  br i1 %256, label %280, label %272

272:                                              ; preds = %231
  %273 = sub nuw nsw i32 4, %255
  %274 = lshr i32 %271, 8
  %275 = shl nsw i32 -1, %273
  %276 = xor i32 %275, -1
  %277 = and i32 %274, %276
  %278 = shl nuw nsw i32 %277, 5
  %279 = xor i32 %278, %271
  br label %280

280:                                              ; preds = %272, %231
  %281 = phi i32 [ %279, %272 ], [ %271, %231 ]
  %282 = ashr i32 %281, 1
  %283 = sext i32 %282 to i64
  %284 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %283
  %285 = load i16, ptr addrspace(3) %284, align 2, !tbaa !27
  %286 = insertelement <4 x i16> poison, i16 %285, i64 0
  %287 = or disjoint i32 %246, 1
  %288 = mul nuw nsw i32 %287, %260
  %289 = add nuw nsw i32 %288, %262
  %290 = add nuw nsw i32 %289, %264
  %291 = add i32 %290, %268
  br i1 %256, label %300, label %292

292:                                              ; preds = %280
  %293 = sub nuw nsw i32 4, %255
  %294 = lshr i32 %291, 8
  %295 = shl nsw i32 -1, %293
  %296 = xor i32 %295, -1
  %297 = and i32 %294, %296
  %298 = shl nuw nsw i32 %297, 5
  %299 = xor i32 %298, %291
  br label %300

300:                                              ; preds = %292, %280
  %301 = phi i32 [ %299, %292 ], [ %291, %280 ]
  %302 = ashr i32 %301, 1
  %303 = sext i32 %302 to i64
  %304 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %303
  %305 = load i16, ptr addrspace(3) %304, align 2, !tbaa !27
  %306 = insertelement <4 x i16> %286, i16 %305, i64 1
  %307 = or disjoint i32 %246, 2
  %308 = mul nuw nsw i32 %307, %260
  %309 = add nuw nsw i32 %308, %262
  %310 = add nuw nsw i32 %309, %264
  %311 = add i32 %310, %268
  br i1 %256, label %320, label %312

312:                                              ; preds = %300
  %313 = sub nuw nsw i32 4, %255
  %314 = lshr i32 %311, 8
  %315 = shl nsw i32 -1, %313
  %316 = xor i32 %315, -1
  %317 = and i32 %314, %316
  %318 = shl nuw nsw i32 %317, 5
  %319 = xor i32 %318, %311
  br label %320

320:                                              ; preds = %312, %300
  %321 = phi i32 [ %319, %312 ], [ %311, %300 ]
  %322 = ashr i32 %321, 1
  %323 = sext i32 %322 to i64
  %324 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %323
  %325 = load i16, ptr addrspace(3) %324, align 2, !tbaa !27
  %326 = insertelement <4 x i16> %306, i16 %325, i64 2
  %327 = or disjoint i32 %246, 3
  %328 = mul nuw nsw i32 %327, %260
  %329 = add nuw nsw i32 %328, %262
  %330 = add nuw nsw i32 %329, %264
  %331 = add i32 %330, %268
  br i1 %256, label %340, label %332

332:                                              ; preds = %320
  %333 = sub nuw nsw i32 4, %255
  %334 = lshr i32 %331, 8
  %335 = shl nsw i32 -1, %333
  %336 = xor i32 %335, -1
  %337 = and i32 %334, %336
  %338 = shl nuw nsw i32 %337, 5
  %339 = xor i32 %338, %331
  br label %340

340:                                              ; preds = %332, %320
  %341 = phi i32 [ %339, %332 ], [ %331, %320 ]
  %342 = ashr i32 %341, 1
  %343 = sext i32 %342 to i64
  %344 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %343
  %345 = load i16, ptr addrspace(3) %344, align 2, !tbaa !27
  %346 = insertelement <4 x i16> %326, i16 %345, i64 3
  %347 = tail call spir_func <4 x float> @__spirv_SubgroupMatrixMultiplyAccumulateINTEL(i32 noundef 16, <4 x i16> noundef %346, <4 x i32> noundef %239, <4 x float> noundef zeroinitializer, i32 noundef 3072) #10
  %348 = or disjoint i32 %261, 1
  %349 = mul nuw nsw i32 %348, %253
  %350 = add nuw nsw i32 %349, %265
  %351 = add nuw nsw i32 %350, %264
  %352 = add i32 %351, %268
  br i1 %256, label %361, label %353

353:                                              ; preds = %340
  %354 = sub nuw nsw i32 4, %255
  %355 = lshr i32 %352, 8
  %356 = shl nsw i32 -1, %354
  %357 = xor i32 %356, -1
  %358 = and i32 %355, %357
  %359 = shl nuw nsw i32 %358, 5
  %360 = xor i32 %359, %352
  br label %361

361:                                              ; preds = %353, %340
  %362 = phi i32 [ %360, %353 ], [ %352, %340 ]
  %363 = ashr i32 %362, 1
  %364 = sext i32 %363 to i64
  %365 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %364
  %366 = load i16, ptr addrspace(3) %365, align 2, !tbaa !27
  %367 = insertelement <4 x i16> poison, i16 %366, i64 0
  %368 = or disjoint i32 %247, 9
  %369 = lshr i32 %368, 3
  %370 = mul nuw nsw i32 %369, %253
  %371 = and i32 %368, 5
  %372 = mul nuw nsw i32 %371, %260
  %373 = add nuw nsw i32 %372, %370
  %374 = add nuw nsw i32 %373, %264
  %375 = add i32 %374, %268
  br i1 %256, label %384, label %376

376:                                              ; preds = %361
  %377 = sub nuw nsw i32 4, %255
  %378 = lshr i32 %375, 8
  %379 = shl nsw i32 -1, %377
  %380 = xor i32 %379, -1
  %381 = and i32 %378, %380
  %382 = shl nuw nsw i32 %381, 5
  %383 = xor i32 %382, %375
  br label %384

384:                                              ; preds = %376, %361
  %385 = phi i32 [ %383, %376 ], [ %375, %361 ]
  %386 = ashr i32 %385, 1
  %387 = sext i32 %386 to i64
  %388 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %387
  %389 = load i16, ptr addrspace(3) %388, align 2, !tbaa !27
  %390 = insertelement <4 x i16> %367, i16 %389, i64 1
  %391 = or disjoint i32 %247, 10
  %392 = lshr i32 %391, 3
  %393 = mul nuw nsw i32 %392, %253
  %394 = and i32 %391, 6
  %395 = mul nuw nsw i32 %394, %260
  %396 = add nuw nsw i32 %395, %393
  %397 = add nuw nsw i32 %396, %264
  %398 = add i32 %397, %268
  br i1 %256, label %407, label %399

399:                                              ; preds = %384
  %400 = sub nuw nsw i32 4, %255
  %401 = lshr i32 %398, 8
  %402 = shl nsw i32 -1, %400
  %403 = xor i32 %402, -1
  %404 = and i32 %401, %403
  %405 = shl nuw nsw i32 %404, 5
  %406 = xor i32 %405, %398
  br label %407

407:                                              ; preds = %399, %384
  %408 = phi i32 [ %406, %399 ], [ %398, %384 ]
  %409 = ashr i32 %408, 1
  %410 = sext i32 %409 to i64
  %411 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %410
  %412 = load i16, ptr addrspace(3) %411, align 2, !tbaa !27
  %413 = insertelement <4 x i16> %390, i16 %412, i64 2
  %414 = or disjoint i32 %247, 11
  %415 = lshr i32 %414, 3
  %416 = mul nuw nsw i32 %415, %253
  %417 = and i32 %414, 7
  %418 = mul nuw nsw i32 %417, %260
  %419 = add nuw nsw i32 %418, %416
  %420 = add nuw nsw i32 %419, %264
  %421 = add i32 %420, %268
  br i1 %256, label %430, label %422

422:                                              ; preds = %407
  %423 = sub nuw nsw i32 4, %255
  %424 = lshr i32 %421, 8
  %425 = shl nsw i32 -1, %423
  %426 = xor i32 %425, -1
  %427 = and i32 %424, %426
  %428 = shl nuw nsw i32 %427, 5
  %429 = xor i32 %428, %421
  br label %430

430:                                              ; preds = %422, %407
  %431 = phi i32 [ %429, %422 ], [ %421, %407 ]
  %432 = ashr i32 %431, 1
  %433 = sext i32 %432 to i64
  %434 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %433
  %435 = load i16, ptr addrspace(3) %434, align 2, !tbaa !27
  %436 = insertelement <4 x i16> %413, i16 %435, i64 3
  %437 = tail call spir_func <4 x float> @__spirv_SubgroupMatrixMultiplyAccumulateINTEL(i32 noundef 16, <4 x i16> noundef %436, <4 x i32> noundef %239, <4 x float> noundef zeroinitializer, i32 noundef 3072) #10
  %438 = sext i32 %8 to i64
  %439 = getelementptr inbounds i8, ptr addrspace(3) %0, i64 %438
  %440 = shl nuw nsw i32 %14, 8
  %441 = zext nneg i32 %440 to i64
  %442 = getelementptr inbounds nuw float, ptr addrspace(3) %439, i64 %441
  %443 = extractelement <4 x float> %347, i64 0
  %444 = shl nuw nsw i32 %53, 6
  %445 = or disjoint i32 %444, %54
  %446 = zext nneg i32 %445 to i64
  %447 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %446
  store float %443, ptr addrspace(3) %447, align 4, !tbaa !29
  %448 = extractelement <4 x float> %347, i64 1
  %449 = or disjoint i32 %445, 16
  %450 = zext nneg i32 %449 to i64
  %451 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %450
  store float %448, ptr addrspace(3) %451, align 4, !tbaa !29
  %452 = extractelement <4 x float> %347, i64 2
  %453 = or disjoint i32 %445, 32
  %454 = zext nneg i32 %453 to i64
  %455 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %454
  store float %452, ptr addrspace(3) %455, align 4, !tbaa !29
  %456 = extractelement <4 x float> %347, i64 3
  %457 = or disjoint i32 %445, 48
  %458 = zext nneg i32 %457 to i64
  %459 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %458
  store float %456, ptr addrspace(3) %459, align 4, !tbaa !29
  %460 = extractelement <4 x float> %437, i64 0
  %461 = or disjoint i32 %445, 128
  %462 = zext nneg i32 %461 to i64
  %463 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %462
  store float %460, ptr addrspace(3) %463, align 4, !tbaa !29
  %464 = extractelement <4 x float> %437, i64 1
  %465 = or disjoint i32 %445, 144
  %466 = zext nneg i32 %465 to i64
  %467 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %466
  store float %464, ptr addrspace(3) %467, align 4, !tbaa !29
  %468 = extractelement <4 x float> %437, i64 2
  %469 = or disjoint i32 %445, 160
  %470 = zext nneg i32 %469 to i64
  %471 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %470
  store float %468, ptr addrspace(3) %471, align 4, !tbaa !29
  %472 = extractelement <4 x float> %437, i64 3
  %473 = or disjoint i32 %445, 176
  %474 = zext nneg i32 %473 to i64
  %475 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %474
  store float %472, ptr addrspace(3) %475, align 4, !tbaa !29
  tail call spir_func void @_Z17sub_group_barrierj(i32 noundef 1) #10
  %476 = shl nuw nsw i32 %52, 2
  %477 = and i32 %476, 112
  %478 = shl i32 %51, 1
  %479 = and i32 %478, 6
  %480 = or disjoint i32 %477, %479
  %481 = zext nneg i32 %480 to i64
  %482 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %481
  %483 = load <2 x float>, ptr addrspace(3) %482, align 4, !tbaa !29
  %484 = or disjoint i32 %477, 128
  %485 = or disjoint i32 %484, %479
  %486 = zext nneg i32 %485 to i64
  %487 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %486
  %488 = load <2 x float>, ptr addrspace(3) %487, align 4, !tbaa !29
  %489 = shufflevector <2 x float> %483, <2 x float> %488, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 poison, i32 poison, i32 poison, i32 poison>
  %490 = or disjoint i32 %479, 8
  %491 = or disjoint i32 %477, %490
  %492 = zext nneg i32 %491 to i64
  %493 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %492
  %494 = load <2 x float>, ptr addrspace(3) %493, align 4, !tbaa !29
  %495 = shufflevector <2 x float> %494, <2 x float> poison, <8 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %496 = shufflevector <8 x float> %489, <8 x float> %495, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 8, i32 9, i32 poison, i32 poison>
  %497 = or disjoint i32 %484, %490
  %498 = zext nneg i32 %497 to i64
  %499 = getelementptr inbounds nuw float, ptr addrspace(3) %442, i64 %498
  %500 = load <2 x float>, ptr addrspace(3) %499, align 4, !tbaa !29
  %501 = shufflevector <2 x float> %500, <2 x float> poison, <8 x i32> <i32 0, i32 1, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison, i32 poison>
  %502 = shufflevector <8 x float> %496, <8 x float> %501, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 8, i32 9>
  %503 = insertelement <8 x float> poison, float %57, i64 0
  %504 = shufflevector <8 x float> %503, <8 x float> poison, <8 x i32> zeroinitializer
  %505 = tail call <8 x float> @llvm.fmuladd.v8f32(<8 x float> %504, <8 x float> %502, <8 x float> %7)
  br label %506

506:                                              ; preds = %430, %16, %9
  %507 = phi <8 x float> [ %7, %9 ], [ %48, %16 ], [ %505, %430 ]
  ret <8 x float> %507
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z16get_sub_group_idv() local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare dso_local spir_func <4 x float> @__spirv_SubgroupMatrixMultiplyAccumulateINTEL(i32 noundef, <4 x i16> noundef, <4 x i32> noundef, <4 x float> noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z17sub_group_barrierj(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <8 x float> @llvm.fmuladd.v8f32(<8 x float>, <8 x float>, <8 x float>) #4

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zlift_wgmma_tile8_ref_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %5, i32 noundef %6, <8 x float> noundef %7) local_unnamed_addr #0 {
  %9 = extractelement <8 x float> %7, i64 0
  %10 = extractelement <8 x float> %7, i64 1
  %11 = extractelement <8 x float> %7, i64 2
  %12 = extractelement <8 x float> %7, i64 3
  %13 = extractelement <8 x float> %7, i64 4
  %14 = extractelement <8 x float> %7, i64 5
  %15 = extractelement <8 x float> %7, i64 6
  %16 = extractelement <8 x float> %7, i64 7
  %17 = shl nsw i32 %5, 3
  %18 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %17, i32 noundef %6, float noundef %9) #10
  %19 = or disjoint i32 %17, 1
  %20 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %19, i32 noundef %6, float noundef %10) #10
  %21 = or disjoint i32 %17, 2
  %22 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %21, i32 noundef %6, float noundef %11) #10
  %23 = or disjoint i32 %17, 3
  %24 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %23, i32 noundef %6, float noundef %12) #10
  %25 = or disjoint i32 %17, 4
  %26 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %25, i32 noundef %6, float noundef %13) #10
  %27 = or disjoint i32 %17, 5
  %28 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %27, i32 noundef %6, float noundef %14) #10
  %29 = or disjoint i32 %17, 6
  %30 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %29, i32 noundef %6, float noundef %15) #10
  %31 = or disjoint i32 %17, 7
  %32 = tail call spir_func float @__zlift_wgmma_elem_f32_f16_f16(ptr addrspace(3) noundef %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %31, i32 noundef %6, float noundef %16) #10
  %33 = insertelement <8 x float> poison, float %18, i64 0
  %34 = insertelement <8 x float> %33, float %20, i64 1
  %35 = insertelement <8 x float> %34, float %22, i64 2
  %36 = insertelement <8 x float> %35, float %24, i64 3
  %37 = insertelement <8 x float> %36, float %26, i64 4
  %38 = insertelement <8 x float> %37, float %28, i64 5
  %39 = insertelement <8 x float> %38, float %30, i64 6
  %40 = insertelement <8 x float> %39, float %32, i64 7
  ret <8 x float> %40
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zlift_wgmma_tile8_f32_f16_f16(ptr addrspace(3) nocapture noundef readonly %0, i32 noundef %1, i64 noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %5, i32 noundef %6, <8 x float> noundef %7) local_unnamed_addr #0 {
  %9 = icmp ne i64 %2, 0
  %10 = icmp ne i64 %4, 0
  %11 = and i1 %9, %10
  br i1 %11, label %12, label %527

12:                                               ; preds = %8
  %13 = tail call spir_func i64 @_Z19get_local_linear_idv() #10
  %14 = shl nsw i32 %5, 4
  %15 = icmp slt i32 %6, 0
  %16 = select i1 %15, float -1.000000e+00, float 1.000000e+00
  %17 = insertelement <2 x i64> poison, i64 %13, i64 0
  %18 = insertelement <2 x i64> %17, i64 %4, i64 1
  %19 = trunc <2 x i64> %18 to <2 x i32>
  %20 = trunc i64 %13 to i32
  %21 = and i32 %20, 8
  %22 = or disjoint i32 %21, %14
  %23 = lshr <2 x i32> %19, <i32 4, i32 12>
  %24 = and <2 x i32> %23, <i32 1, i32 262128>
  %25 = lshr i64 %4, 28
  %26 = trunc i64 %25 to i32
  %27 = and i32 %26, 262128
  %28 = lshr i64 %4, 62
  %29 = trunc nuw nsw i64 %28 to i32
  %30 = icmp eq i32 %29, 0
  %31 = add nuw nsw i32 %29, 31
  %32 = and i32 %31, 31
  %33 = lshr i32 128, %32
  %34 = select i1 %30, i32 16, i32 %33
  %35 = ashr exact i32 %22, 3
  %36 = mul nsw i32 %35, %27
  %37 = extractelement <2 x i32> %24, i64 0
  %38 = extractelement <2 x i32> %24, i64 1
  %39 = mul nuw nsw i32 %37, %38
  %40 = and i32 %20, 7
  %41 = mul nuw nsw i32 %40, %34
  %42 = add i32 %3, 2
  %43 = add i32 %42, %41
  %44 = add i32 %43, %39
  %45 = add i32 %44, %36
  br i1 %30, label %54, label %46

46:                                               ; preds = %12
  %47 = sub nuw nsw i32 4, %29
  %48 = lshr i32 %45, 8
  %49 = shl nsw i32 -1, %47
  %50 = xor i32 %49, -1
  %51 = and i32 %48, %50
  %52 = shl nuw nsw i32 %51, 5
  %53 = xor i32 %52, %45
  br label %54

54:                                               ; preds = %46, %12
  %55 = phi i32 [ %53, %46 ], [ %45, %12 ]
  %56 = ashr i32 %55, 1
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %57
  %59 = load i16, ptr addrspace(3) %58, align 2, !tbaa !27
  %60 = zext i16 %59 to i32
  %61 = shl nuw i32 %60, 16
  %62 = add i32 %41, %3
  %63 = add i32 %62, %39
  %64 = add i32 %63, %36
  br i1 %30, label %73, label %65

65:                                               ; preds = %54
  %66 = sub nuw nsw i32 4, %29
  %67 = lshr i32 %64, 8
  %68 = shl nsw i32 -1, %66
  %69 = xor i32 %68, -1
  %70 = and i32 %67, %69
  %71 = shl nuw nsw i32 %70, 5
  %72 = xor i32 %71, %64
  br label %73

73:                                               ; preds = %65, %54
  %74 = phi i32 [ %72, %65 ], [ %64, %54 ]
  %75 = ashr i32 %74, 1
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %76
  %78 = load i16, ptr addrspace(3) %77, align 2, !tbaa !27
  %79 = zext i16 %78 to i32
  %80 = or disjoint i32 %61, %79
  %81 = insertelement <4 x i32> poison, i32 %80, i64 0
  %82 = add i32 %3, 6
  %83 = add i32 %82, %41
  %84 = add i32 %83, %39
  %85 = add i32 %84, %36
  br i1 %30, label %94, label %86

86:                                               ; preds = %73
  %87 = sub nuw nsw i32 4, %29
  %88 = lshr i32 %85, 8
  %89 = shl nsw i32 -1, %87
  %90 = xor i32 %89, -1
  %91 = and i32 %88, %90
  %92 = shl nuw nsw i32 %91, 5
  %93 = xor i32 %92, %85
  br label %94

94:                                               ; preds = %86, %73
  %95 = phi i32 [ %93, %86 ], [ %85, %73 ]
  %96 = ashr i32 %95, 1
  %97 = sext i32 %96 to i64
  %98 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %97
  %99 = load i16, ptr addrspace(3) %98, align 2, !tbaa !27
  %100 = zext i16 %99 to i32
  %101 = shl nuw i32 %100, 16
  %102 = add i32 %3, 4
  %103 = add i32 %102, %41
  %104 = add i32 %103, %39
  %105 = add i32 %104, %36
  br i1 %30, label %114, label %106

106:                                              ; preds = %94
  %107 = sub nuw nsw i32 4, %29
  %108 = lshr i32 %105, 8
  %109 = shl nsw i32 -1, %107
  %110 = xor i32 %109, -1
  %111 = and i32 %108, %110
  %112 = shl nuw nsw i32 %111, 5
  %113 = xor i32 %112, %105
  br label %114

114:                                              ; preds = %106, %94
  %115 = phi i32 [ %113, %106 ], [ %105, %94 ]
  %116 = ashr i32 %115, 1
  %117 = sext i32 %116 to i64
  %118 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %117
  %119 = load i16, ptr addrspace(3) %118, align 2, !tbaa !27
  %120 = zext i16 %119 to i32
  %121 = or disjoint i32 %101, %120
  %122 = insertelement <4 x i32> %81, i32 %121, i64 1
  %123 = add i32 %3, 10
  %124 = add i32 %123, %41
  %125 = add i32 %124, %39
  %126 = add i32 %125, %36
  br i1 %30, label %135, label %127

127:                                              ; preds = %114
  %128 = sub nuw nsw i32 4, %29
  %129 = lshr i32 %126, 8
  %130 = shl nsw i32 -1, %128
  %131 = xor i32 %130, -1
  %132 = and i32 %129, %131
  %133 = shl nuw nsw i32 %132, 5
  %134 = xor i32 %133, %126
  br label %135

135:                                              ; preds = %127, %114
  %136 = phi i32 [ %134, %127 ], [ %126, %114 ]
  %137 = ashr i32 %136, 1
  %138 = sext i32 %137 to i64
  %139 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %138
  %140 = load i16, ptr addrspace(3) %139, align 2, !tbaa !27
  %141 = zext i16 %140 to i32
  %142 = shl nuw i32 %141, 16
  %143 = add i32 %3, 8
  %144 = add i32 %143, %41
  %145 = add i32 %144, %39
  %146 = add i32 %145, %36
  br i1 %30, label %155, label %147

147:                                              ; preds = %135
  %148 = sub nuw nsw i32 4, %29
  %149 = lshr i32 %146, 8
  %150 = shl nsw i32 -1, %148
  %151 = xor i32 %150, -1
  %152 = and i32 %149, %151
  %153 = shl nuw nsw i32 %152, 5
  %154 = xor i32 %153, %146
  br label %155

155:                                              ; preds = %147, %135
  %156 = phi i32 [ %154, %147 ], [ %146, %135 ]
  %157 = ashr i32 %156, 1
  %158 = sext i32 %157 to i64
  %159 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %158
  %160 = load i16, ptr addrspace(3) %159, align 2, !tbaa !27
  %161 = zext i16 %160 to i32
  %162 = or disjoint i32 %142, %161
  %163 = insertelement <4 x i32> %122, i32 %162, i64 2
  %164 = add i32 %3, 14
  %165 = add i32 %164, %41
  %166 = add i32 %165, %39
  %167 = add i32 %166, %36
  br i1 %30, label %176, label %168

168:                                              ; preds = %155
  %169 = sub nuw nsw i32 4, %29
  %170 = lshr i32 %167, 8
  %171 = shl nsw i32 -1, %169
  %172 = xor i32 %171, -1
  %173 = and i32 %170, %172
  %174 = shl nuw nsw i32 %173, 5
  %175 = xor i32 %174, %167
  br label %176

176:                                              ; preds = %168, %155
  %177 = phi i32 [ %175, %168 ], [ %167, %155 ]
  %178 = ashr i32 %177, 1
  %179 = sext i32 %178 to i64
  %180 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %179
  %181 = load i16, ptr addrspace(3) %180, align 2, !tbaa !27
  %182 = zext i16 %181 to i32
  %183 = shl nuw i32 %182, 16
  %184 = add i32 %3, 12
  %185 = add i32 %184, %41
  %186 = add i32 %185, %39
  %187 = add i32 %186, %36
  br i1 %30, label %196, label %188

188:                                              ; preds = %176
  %189 = sub nuw nsw i32 4, %29
  %190 = lshr i32 %187, 8
  %191 = shl nsw i32 -1, %189
  %192 = xor i32 %191, -1
  %193 = and i32 %190, %192
  %194 = shl nuw nsw i32 %193, 5
  %195 = xor i32 %194, %187
  br label %196

196:                                              ; preds = %188, %176
  %197 = phi i32 [ %195, %188 ], [ %187, %176 ]
  %198 = ashr i32 %197, 1
  %199 = sext i32 %198 to i64
  %200 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %199
  %201 = load i16, ptr addrspace(3) %200, align 2, !tbaa !27
  %202 = zext i16 %201 to i32
  %203 = or disjoint i32 %183, %202
  %204 = insertelement <4 x i32> %163, i32 %203, i64 3
  %205 = and i64 %13, 15
  %206 = getelementptr inbounds nuw [16 x i8], ptr addrspace(2) @ZLIFT_DPAS_K, i64 0, i64 %205
  %207 = load i8, ptr addrspace(2) %206, align 1, !tbaa !12
  %208 = zext i8 %207 to i32
  %209 = lshr i32 %20, 1
  %210 = and i32 %209, 48
  %211 = shl nuw nsw i32 %37, 2
  %212 = or disjoint i32 %211, %210
  %213 = trunc i64 %2 to i32
  %214 = lshr i32 %213, 12
  %215 = and i32 %214, 262128
  %216 = lshr i64 %2, 28
  %217 = trunc i64 %216 to i32
  %218 = and i32 %217, 262128
  %219 = lshr i64 %2, 62
  %220 = trunc nuw nsw i64 %219 to i32
  %221 = icmp eq i32 %220, 0
  %222 = add nuw nsw i32 %220, 31
  %223 = and i32 %222, 31
  %224 = lshr i32 128, %223
  %225 = select i1 %221, i32 16, i32 %224
  %226 = lshr exact i32 %210, 3
  %227 = mul nuw nsw i32 %226, %218
  %228 = lshr i32 %208, 3
  %229 = mul nuw nsw i32 %228, %215
  %230 = mul nuw nsw i32 %211, %225
  %231 = shl nuw nsw i32 %208, 1
  %232 = and i32 %231, 14
  %233 = add i32 %232, %1
  %234 = add i32 %233, %229
  %235 = add i32 %234, %227
  %236 = add i32 %235, %230
  br i1 %221, label %245, label %237

237:                                              ; preds = %196
  %238 = sub nuw nsw i32 4, %220
  %239 = lshr i32 %236, 8
  %240 = shl nsw i32 -1, %238
  %241 = xor i32 %240, -1
  %242 = and i32 %239, %241
  %243 = shl nuw nsw i32 %242, 5
  %244 = xor i32 %243, %236
  br label %245

245:                                              ; preds = %237, %196
  %246 = phi i32 [ %244, %237 ], [ %236, %196 ]
  %247 = ashr i32 %246, 1
  %248 = sext i32 %247 to i64
  %249 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %248
  %250 = load i16, ptr addrspace(3) %249, align 2, !tbaa !27
  %251 = insertelement <4 x i16> poison, i16 %250, i64 0
  %252 = or disjoint i32 %211, 1
  %253 = mul nuw nsw i32 %252, %225
  %254 = add nuw nsw i32 %253, %227
  %255 = add nuw nsw i32 %254, %229
  %256 = add i32 %255, %233
  br i1 %221, label %265, label %257

257:                                              ; preds = %245
  %258 = sub nuw nsw i32 4, %220
  %259 = lshr i32 %256, 8
  %260 = shl nsw i32 -1, %258
  %261 = xor i32 %260, -1
  %262 = and i32 %259, %261
  %263 = shl nuw nsw i32 %262, 5
  %264 = xor i32 %263, %256
  br label %265

265:                                              ; preds = %257, %245
  %266 = phi i32 [ %264, %257 ], [ %256, %245 ]
  %267 = ashr i32 %266, 1
  %268 = sext i32 %267 to i64
  %269 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %268
  %270 = load i16, ptr addrspace(3) %269, align 2, !tbaa !27
  %271 = insertelement <4 x i16> %251, i16 %270, i64 1
  %272 = or disjoint i32 %211, 2
  %273 = mul nuw nsw i32 %272, %225
  %274 = add nuw nsw i32 %273, %227
  %275 = add nuw nsw i32 %274, %229
  %276 = add i32 %275, %233
  br i1 %221, label %285, label %277

277:                                              ; preds = %265
  %278 = sub nuw nsw i32 4, %220
  %279 = lshr i32 %276, 8
  %280 = shl nsw i32 -1, %278
  %281 = xor i32 %280, -1
  %282 = and i32 %279, %281
  %283 = shl nuw nsw i32 %282, 5
  %284 = xor i32 %283, %276
  br label %285

285:                                              ; preds = %277, %265
  %286 = phi i32 [ %284, %277 ], [ %276, %265 ]
  %287 = ashr i32 %286, 1
  %288 = sext i32 %287 to i64
  %289 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %288
  %290 = load i16, ptr addrspace(3) %289, align 2, !tbaa !27
  %291 = insertelement <4 x i16> %271, i16 %290, i64 2
  %292 = or disjoint i32 %211, 3
  %293 = mul nuw nsw i32 %292, %225
  %294 = add nuw nsw i32 %293, %227
  %295 = add nuw nsw i32 %294, %229
  %296 = add i32 %295, %233
  br i1 %221, label %305, label %297

297:                                              ; preds = %285
  %298 = sub nuw nsw i32 4, %220
  %299 = lshr i32 %296, 8
  %300 = shl nsw i32 -1, %298
  %301 = xor i32 %300, -1
  %302 = and i32 %299, %301
  %303 = shl nuw nsw i32 %302, 5
  %304 = xor i32 %303, %296
  br label %305

305:                                              ; preds = %297, %285
  %306 = phi i32 [ %304, %297 ], [ %296, %285 ]
  %307 = ashr i32 %306, 1
  %308 = sext i32 %307 to i64
  %309 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %308
  %310 = load i16, ptr addrspace(3) %309, align 2, !tbaa !27
  %311 = insertelement <4 x i16> %291, i16 %310, i64 3
  %312 = tail call spir_func <4 x float> @__spirv_SubgroupMatrixMultiplyAccumulateINTEL(i32 noundef 16, <4 x i16> noundef %311, <4 x i32> noundef %204, <4 x float> noundef zeroinitializer, i32 noundef 3072) #10
  %313 = or disjoint i32 %226, 1
  %314 = mul nuw nsw i32 %313, %218
  %315 = add nuw nsw i32 %314, %230
  %316 = add nuw nsw i32 %315, %229
  %317 = add i32 %316, %233
  br i1 %221, label %326, label %318

318:                                              ; preds = %305
  %319 = sub nuw nsw i32 4, %220
  %320 = lshr i32 %317, 8
  %321 = shl nsw i32 -1, %319
  %322 = xor i32 %321, -1
  %323 = and i32 %320, %322
  %324 = shl nuw nsw i32 %323, 5
  %325 = xor i32 %324, %317
  br label %326

326:                                              ; preds = %318, %305
  %327 = phi i32 [ %325, %318 ], [ %317, %305 ]
  %328 = ashr i32 %327, 1
  %329 = sext i32 %328 to i64
  %330 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %329
  %331 = load i16, ptr addrspace(3) %330, align 2, !tbaa !27
  %332 = insertelement <4 x i16> poison, i16 %331, i64 0
  %333 = or disjoint i32 %212, 9
  %334 = lshr i32 %333, 3
  %335 = mul nuw nsw i32 %334, %218
  %336 = and i32 %333, 5
  %337 = mul nuw nsw i32 %336, %225
  %338 = add nuw nsw i32 %337, %335
  %339 = add nuw nsw i32 %338, %229
  %340 = add i32 %339, %233
  br i1 %221, label %349, label %341

341:                                              ; preds = %326
  %342 = sub nuw nsw i32 4, %220
  %343 = lshr i32 %340, 8
  %344 = shl nsw i32 -1, %342
  %345 = xor i32 %344, -1
  %346 = and i32 %343, %345
  %347 = shl nuw nsw i32 %346, 5
  %348 = xor i32 %347, %340
  br label %349

349:                                              ; preds = %341, %326
  %350 = phi i32 [ %348, %341 ], [ %340, %326 ]
  %351 = ashr i32 %350, 1
  %352 = sext i32 %351 to i64
  %353 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %352
  %354 = load i16, ptr addrspace(3) %353, align 2, !tbaa !27
  %355 = insertelement <4 x i16> %332, i16 %354, i64 1
  %356 = or disjoint i32 %212, 10
  %357 = lshr i32 %356, 3
  %358 = mul nuw nsw i32 %357, %218
  %359 = and i32 %356, 6
  %360 = mul nuw nsw i32 %359, %225
  %361 = add nuw nsw i32 %360, %358
  %362 = add nuw nsw i32 %361, %229
  %363 = add i32 %362, %233
  br i1 %221, label %372, label %364

364:                                              ; preds = %349
  %365 = sub nuw nsw i32 4, %220
  %366 = lshr i32 %363, 8
  %367 = shl nsw i32 -1, %365
  %368 = xor i32 %367, -1
  %369 = and i32 %366, %368
  %370 = shl nuw nsw i32 %369, 5
  %371 = xor i32 %370, %363
  br label %372

372:                                              ; preds = %364, %349
  %373 = phi i32 [ %371, %364 ], [ %363, %349 ]
  %374 = ashr i32 %373, 1
  %375 = sext i32 %374 to i64
  %376 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %375
  %377 = load i16, ptr addrspace(3) %376, align 2, !tbaa !27
  %378 = insertelement <4 x i16> %355, i16 %377, i64 2
  %379 = or disjoint i32 %212, 11
  %380 = lshr i32 %379, 3
  %381 = mul nuw nsw i32 %380, %218
  %382 = and i32 %379, 7
  %383 = mul nuw nsw i32 %382, %225
  %384 = add nuw nsw i32 %383, %381
  %385 = add nuw nsw i32 %384, %229
  %386 = add i32 %385, %233
  br i1 %221, label %395, label %387

387:                                              ; preds = %372
  %388 = sub nuw nsw i32 4, %220
  %389 = lshr i32 %386, 8
  %390 = shl nsw i32 -1, %388
  %391 = xor i32 %390, -1
  %392 = and i32 %389, %391
  %393 = shl nuw nsw i32 %392, 5
  %394 = xor i32 %393, %386
  br label %395

395:                                              ; preds = %387, %372
  %396 = phi i32 [ %394, %387 ], [ %386, %372 ]
  %397 = ashr i32 %396, 1
  %398 = sext i32 %397 to i64
  %399 = getelementptr inbounds i16, ptr addrspace(3) %0, i64 %398
  %400 = load i16, ptr addrspace(3) %399, align 2, !tbaa !27
  %401 = insertelement <4 x i16> %378, i16 %400, i64 3
  %402 = tail call spir_func <4 x float> @__spirv_SubgroupMatrixMultiplyAccumulateINTEL(i32 noundef 16, <4 x i16> noundef %401, <4 x i32> noundef %204, <4 x float> noundef zeroinitializer, i32 noundef 3072) #10
  %403 = lshr i32 %20, 2
  %404 = and i32 %403, 3
  %405 = and i32 %20, 16
  %406 = shl i32 %20, 1
  %407 = and i32 %406, 6
  %408 = or disjoint i32 %407, %405
  %409 = extractelement <4 x float> %312, i64 0
  %410 = fptosi float %409 to i32
  %411 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %410, i32 noundef range(i32 0, 32) %408) #10
  %412 = extractelement <4 x float> %312, i64 1
  %413 = fptosi float %412 to i32
  %414 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %413, i32 noundef range(i32 0, 32) %408) #10
  %415 = extractelement <4 x float> %312, i64 2
  %416 = fptosi float %415 to i32
  %417 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %416, i32 noundef range(i32 0, 32) %408) #10
  %418 = extractelement <4 x float> %312, i64 3
  %419 = fptosi float %418 to i32
  %420 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %419, i32 noundef range(i32 0, 32) %408) #10
  switch i32 %404, label %422 [
    i32 0, label %425
    i32 1, label %421
  ]

421:                                              ; preds = %395
  br label %425

422:                                              ; preds = %395
  %423 = icmp eq i32 %404, 2
  %424 = select i1 %423, i32 %417, i32 %420
  br label %425

425:                                              ; preds = %422, %421, %395
  %426 = phi i32 [ %414, %421 ], [ %424, %422 ], [ %411, %395 ]
  %427 = sitofp i32 %426 to float
  %428 = insertelement <8 x float> poison, float %427, i64 0
  %429 = or disjoint i32 %408, 1
  %430 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %410, i32 noundef range(i32 0, 32) %429) #10
  %431 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %413, i32 noundef range(i32 0, 32) %429) #10
  %432 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %416, i32 noundef range(i32 0, 32) %429) #10
  %433 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %419, i32 noundef range(i32 0, 32) %429) #10
  switch i32 %404, label %435 [
    i32 0, label %438
    i32 1, label %434
  ]

434:                                              ; preds = %425
  br label %438

435:                                              ; preds = %425
  %436 = icmp eq i32 %404, 2
  %437 = select i1 %436, i32 %432, i32 %433
  br label %438

438:                                              ; preds = %435, %434, %425
  %439 = phi i32 [ %431, %434 ], [ %437, %435 ], [ %430, %425 ]
  %440 = sitofp i32 %439 to float
  %441 = insertelement <8 x float> %428, float %440, i64 1
  %442 = extractelement <4 x float> %402, i64 0
  %443 = fptosi float %442 to i32
  %444 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %443, i32 noundef range(i32 0, 32) %408) #10
  %445 = extractelement <4 x float> %402, i64 1
  %446 = fptosi float %445 to i32
  %447 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %446, i32 noundef range(i32 0, 32) %408) #10
  %448 = extractelement <4 x float> %402, i64 2
  %449 = fptosi float %448 to i32
  %450 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %449, i32 noundef range(i32 0, 32) %408) #10
  %451 = extractelement <4 x float> %402, i64 3
  %452 = fptosi float %451 to i32
  %453 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %452, i32 noundef range(i32 0, 32) %408) #10
  switch i32 %404, label %455 [
    i32 0, label %458
    i32 1, label %454
  ]

454:                                              ; preds = %438
  br label %458

455:                                              ; preds = %438
  %456 = icmp eq i32 %404, 2
  %457 = select i1 %456, i32 %450, i32 %453
  br label %458

458:                                              ; preds = %455, %454, %438
  %459 = phi i32 [ %447, %454 ], [ %457, %455 ], [ %444, %438 ]
  %460 = sitofp i32 %459 to float
  %461 = insertelement <8 x float> %441, float %460, i64 2
  %462 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %443, i32 noundef range(i32 0, 32) %429) #10
  %463 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %446, i32 noundef range(i32 0, 32) %429) #10
  %464 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %449, i32 noundef range(i32 0, 32) %429) #10
  %465 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %452, i32 noundef range(i32 0, 32) %429) #10
  switch i32 %404, label %467 [
    i32 0, label %470
    i32 1, label %466
  ]

466:                                              ; preds = %458
  br label %470

467:                                              ; preds = %458
  %468 = icmp eq i32 %404, 2
  %469 = select i1 %468, i32 %464, i32 %465
  br label %470

470:                                              ; preds = %467, %466, %458
  %471 = phi i32 [ %463, %466 ], [ %469, %467 ], [ %462, %458 ]
  %472 = sitofp i32 %471 to float
  %473 = insertelement <8 x float> %461, float %472, i64 3
  %474 = or disjoint i32 %408, 8
  %475 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %410, i32 noundef range(i32 0, 32) %474) #10
  %476 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %413, i32 noundef range(i32 0, 32) %474) #10
  %477 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %416, i32 noundef range(i32 0, 32) %474) #10
  %478 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %419, i32 noundef range(i32 0, 32) %474) #10
  switch i32 %404, label %480 [
    i32 0, label %483
    i32 1, label %479
  ]

479:                                              ; preds = %470
  br label %483

480:                                              ; preds = %470
  %481 = icmp eq i32 %404, 2
  %482 = select i1 %481, i32 %477, i32 %478
  br label %483

483:                                              ; preds = %480, %479, %470
  %484 = phi i32 [ %476, %479 ], [ %482, %480 ], [ %475, %470 ]
  %485 = sitofp i32 %484 to float
  %486 = insertelement <8 x float> %473, float %485, i64 4
  %487 = or disjoint i32 %408, 9
  %488 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %410, i32 noundef range(i32 0, 32) %487) #10
  %489 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %413, i32 noundef range(i32 0, 32) %487) #10
  %490 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %416, i32 noundef range(i32 0, 32) %487) #10
  %491 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %419, i32 noundef range(i32 0, 32) %487) #10
  switch i32 %404, label %493 [
    i32 0, label %496
    i32 1, label %492
  ]

492:                                              ; preds = %483
  br label %496

493:                                              ; preds = %483
  %494 = icmp eq i32 %404, 2
  %495 = select i1 %494, i32 %490, i32 %491
  br label %496

496:                                              ; preds = %493, %492, %483
  %497 = phi i32 [ %489, %492 ], [ %495, %493 ], [ %488, %483 ]
  %498 = sitofp i32 %497 to float
  %499 = insertelement <8 x float> %486, float %498, i64 5
  %500 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %443, i32 noundef range(i32 0, 32) %474) #10
  %501 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %446, i32 noundef range(i32 0, 32) %474) #10
  %502 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %449, i32 noundef range(i32 0, 32) %474) #10
  %503 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %452, i32 noundef range(i32 0, 32) %474) #10
  switch i32 %404, label %505 [
    i32 0, label %508
    i32 1, label %504
  ]

504:                                              ; preds = %496
  br label %508

505:                                              ; preds = %496
  %506 = icmp eq i32 %404, 2
  %507 = select i1 %506, i32 %502, i32 %503
  br label %508

508:                                              ; preds = %505, %504, %496
  %509 = phi i32 [ %501, %504 ], [ %507, %505 ], [ %500, %496 ]
  %510 = sitofp i32 %509 to float
  %511 = insertelement <8 x float> %499, float %510, i64 6
  %512 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %443, i32 noundef range(i32 0, 32) %487) #10
  %513 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %446, i32 noundef range(i32 0, 32) %487) #10
  %514 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %449, i32 noundef range(i32 0, 32) %487) #10
  %515 = tail call spir_func i32 @intel_sub_group_shuffle(i32 noundef %452, i32 noundef range(i32 0, 32) %487) #10
  switch i32 %404, label %517 [
    i32 0, label %520
    i32 1, label %516
  ]

516:                                              ; preds = %508
  br label %520

517:                                              ; preds = %508
  %518 = icmp eq i32 %404, 2
  %519 = select i1 %518, i32 %514, i32 %515
  br label %520

520:                                              ; preds = %517, %516, %508
  %521 = phi i32 [ %513, %516 ], [ %519, %517 ], [ %512, %508 ]
  %522 = sitofp i32 %521 to float
  %523 = insertelement <8 x float> %511, float %522, i64 7
  %524 = insertelement <8 x float> poison, float %16, i64 0
  %525 = shufflevector <8 x float> %524, <8 x float> poison, <8 x i32> zeroinitializer
  %526 = tail call <8 x float> @llvm.fmuladd.v8f32(<8 x float> %525, <8 x float> %523, <8 x float> %7)
  br label %527

527:                                              ; preds = %520, %8
  %528 = phi <8 x float> [ %526, %520 ], [ %7, %8 ]
  ret <8 x float> %528
}

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zluda_ptx_impl_sreg_tid(i8 noundef zeroext %0) local_unnamed_addr #5 {
  %2 = zext i8 %0 to i32
  %3 = tail call spir_func i64 @_Z12get_local_idj(i32 noundef %2) #11
  %4 = trunc i64 %3 to i32
  ret i32 %4
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func i64 @_Z12get_local_idj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zluda_ptx_impl_sreg_ntid(i8 noundef zeroext %0) local_unnamed_addr #5 {
  %2 = zext i8 %0 to i32
  %3 = tail call spir_func i64 @_Z14get_local_sizej(i32 noundef %2) #11
  %4 = trunc i64 %3 to i32
  ret i32 %4
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func i64 @_Z14get_local_sizej(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zluda_ptx_impl_sreg_ctaid(i8 noundef zeroext %0) local_unnamed_addr #5 {
  %2 = zext i8 %0 to i32
  %3 = tail call spir_func i64 @_Z12get_group_idj(i32 noundef %2) #11
  %4 = trunc i64 %3 to i32
  ret i32 %4
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func i64 @_Z12get_group_idj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func i32 @__zluda_ptx_impl_sreg_nctaid(i8 noundef zeroext %0) local_unnamed_addr #5 {
  %2 = zext i8 %0 to i32
  %3 = tail call spir_func i64 @_Z14get_num_groupsj(i32 noundef %2) #11
  %4 = trunc i64 %3 to i32
  ret i32 %4
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func i64 @_Z14get_num_groupsj(i32 noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_sreg_laneid() local_unnamed_addr #0 {
  %1 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  ret i32 %1
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func noundef i32 @__zluda_ptx_impl_sreg_warpsize() local_unnamed_addr #3 {
  ret i32 32
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func noundef i32 @__zluda_ptx_impl_sreg_clusterid(i8 noundef zeroext %0) local_unnamed_addr #3 {
  ret i32 0
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr spir_func noundef i32 @__zluda_ptx_impl_sreg_nclusterid(i8 noundef zeroext %0) local_unnamed_addr #3 {
  ret i32 1
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zluda_ptx_impl_bar_sync(i32 noundef %0) local_unnamed_addr #0 {
  tail call spir_func void @_Z7barrierj(i32 noundef 3) #10
  ret void
}

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z7barrierj(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_activemask() local_unnamed_addr #0 {
  %1 = tail call spir_func i32 @__zlift_activemask() #10
  ret i32 %1
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_match_any_sync_b32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @__zlift_match_any_b32(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_prmt_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @__zlift_prmt_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2) #10
  ret i32 %4
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_bfi_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @__zlift_bfi_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #10
  ret i32 %5
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i64 @__zluda_ptx_impl_bfi_b64(i64 noundef %0, i64 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i64 @__zlift_bfi_b64(i64 noundef %0, i64 noundef %1, i32 noundef %2, i32 noundef %3) #10
  ret i64 %5
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_bfe_u32(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @__zlift_bfe_u32(i32 noundef %0, i32 noundef %1, i32 noundef %2) #10
  ret i32 %4
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_bfe_s32(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @__zlift_bfe_s32(i32 noundef %0, i32 noundef %1, i32 noundef %2) #10
  ret i32 %4
}

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_rcp_approx_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z12native_recipf(float noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z12native_recipf(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_rsqrt_approx_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z12native_rsqrtf(float noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z12native_rsqrtf(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_ex2_approx_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z11native_exp2f(float noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z11native_exp2f(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_lg2_approx_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z11native_log2f(float noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z11native_log2f(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_sin_approx_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z10native_sinf(float noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z10native_sinf(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_cos_approx_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z10native_cosf(float noundef %0) #11
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z10native_cosf(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr spir_func float @__zluda_ptx_impl_sqrt_rn_f32(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call spir_func float @_Z4sqrtf(float noundef %0) #11, !fpmath !31
  ret float %2
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func float @_Z4sqrtf(float noundef) local_unnamed_addr #2

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_redux_sync_add_s32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z20sub_group_reduce_addi(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_redux_sync_min_s32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z20sub_group_reduce_mini(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z20sub_group_reduce_mini(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_redux_sync_max_s32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z20sub_group_reduce_maxi(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z20sub_group_reduce_maxi(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_redux_sync_add_u32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z20sub_group_reduce_addj(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z20sub_group_reduce_addj(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_redux_sync_min_u32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z20sub_group_reduce_minj(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z20sub_group_reduce_minj(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_redux_sync_max_u32(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call spir_func i32 @_Z20sub_group_reduce_maxj(i32 noundef %0) #10
  ret i32 %3
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z20sub_group_reduce_maxj(i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_shfl_sync_down_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = tail call spir_func i32 @_Z28intel_sub_group_shuffle_downiij(i32 noundef %0, i32 noundef %0, i32 noundef %1) #10
  %7 = add i32 %5, %1
  %8 = icmp ult i32 %7, 32
  %9 = select i1 %8, i32 %6, i32 %0
  ret i32 %9
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z28intel_sub_group_shuffle_downiij(i32 noundef, i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_shfl_sync_up_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = tail call spir_func i32 @_Z26intel_sub_group_shuffle_upiij(i32 noundef %0, i32 noundef %0, i32 noundef %1) #10
  %7 = icmp ult i32 %5, %1
  %8 = select i1 %7, i32 %0, i32 %6
  ret i32 %8
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z26intel_sub_group_shuffle_upiij(i32 noundef, i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_shfl_sync_bfly_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z27intel_sub_group_shuffle_xorij(i32 noundef %0, i32 noundef %1) #10
  ret i32 %5
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z27intel_sub_group_shuffle_xorij(i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_shfl_sync_idx_b32(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %0, i32 noundef %1) #10
  ret i32 %5
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zluda_ptx_impl_shfl_sync_down_b32_pred(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = tail call spir_func i32 @_Z28intel_sub_group_shuffle_downiij(i32 noundef %0, i32 noundef %0, i32 noundef %1) #10
  %8 = add i32 %6, %1
  %9 = icmp ult i32 %8, 32
  %10 = select i1 %9, i32 %7, i32 %0
  %11 = insertelement <2 x i32> poison, i32 %10, i64 0
  %12 = add i32 %5, %1
  %13 = icmp ult i32 %12, 32
  %14 = zext i1 %13 to i32
  %15 = insertelement <2 x i32> %11, i32 %14, i64 1
  ret <2 x i32> %15
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zluda_ptx_impl_shfl_sync_up_b32_pred(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = tail call spir_func i32 @_Z26intel_sub_group_shuffle_upiij(i32 noundef %0, i32 noundef %0, i32 noundef %1) #10
  %8 = icmp ult i32 %6, %1
  %9 = select i1 %8, i32 %0, i32 %7
  %10 = insertelement <2 x i32> poison, i32 %9, i64 0
  %11 = icmp uge i32 %5, %1
  %12 = zext i1 %11 to i32
  %13 = insertelement <2 x i32> %10, i32 %12, i64 1
  ret <2 x i32> %13
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zluda_ptx_impl_shfl_sync_bfly_b32_pred(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z27intel_sub_group_shuffle_xorij(i32 noundef %0, i32 noundef %1) #10
  %6 = insertelement <2 x i32> <i32 poison, i32 1>, i32 %5, i64 0
  ret <2 x i32> %6
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <2 x i32> @__zluda_ptx_impl_shfl_sync_idx_b32_pred(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %0, i32 noundef %1) #10
  %6 = insertelement <2 x i32> <i32 poison, i32 1>, i32 %5, i64 0
  ret <2 x i32> %6
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func zeroext i1 @__zluda_ptx_impl_elect_sync_pred(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call spir_func i32 @__zlift_elect_sync() #10
  %3 = icmp ne i32 %2, 0
  ret i1 %3
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_a_row_f16_global(i64 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = inttoptr i64 %0 to ptr addrspace(1)
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 1
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 8
  %8 = mul i32 %5, %1
  %9 = add i32 %8, %7
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %10
  %12 = load i16, ptr addrspace(1) %11, align 2, !tbaa !32
  %13 = add i32 %9, 1
  %14 = zext i32 %13 to i64
  %15 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %14
  %16 = load i16, ptr addrspace(1) %15, align 2, !tbaa !32
  %17 = add i32 %9, 2
  %18 = zext i32 %17 to i64
  %19 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %18
  %20 = load i16, ptr addrspace(1) %19, align 2, !tbaa !32
  %21 = add i32 %9, 3
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %22
  %24 = load i16, ptr addrspace(1) %23, align 2, !tbaa !32
  %25 = add i32 %9, 4
  %26 = zext i32 %25 to i64
  %27 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %26
  %28 = load i16, ptr addrspace(1) %27, align 2, !tbaa !32
  %29 = add i32 %9, 5
  %30 = zext i32 %29 to i64
  %31 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %30
  %32 = load i16, ptr addrspace(1) %31, align 2, !tbaa !32
  %33 = add i32 %9, 6
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %34
  %36 = load i16, ptr addrspace(1) %35, align 2, !tbaa !32
  %37 = add i32 %9, 7
  %38 = zext i32 %37 to i64
  %39 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %38
  %40 = load i16, ptr addrspace(1) %39, align 2, !tbaa !32
  %41 = insertelement <8 x i16> poison, i16 %12, i64 0
  %42 = insertelement <8 x i16> %41, i16 %16, i64 1
  %43 = insertelement <8 x i16> %42, i16 %20, i64 2
  %44 = insertelement <8 x i16> %43, i16 %24, i64 3
  %45 = insertelement <8 x i16> %44, i16 %28, i64 4
  %46 = insertelement <8 x i16> %45, i16 %32, i64 5
  %47 = insertelement <8 x i16> %46, i16 %36, i64 6
  %48 = insertelement <8 x i16> %47, i16 %40, i64 7
  %49 = zext <8 x i16> %48 to <8 x i32>
  ret <8 x i32> %49
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_a_col_f16_global(i64 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = inttoptr i64 %0 to ptr addrspace(1)
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 1
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 8
  %8 = mul i32 %7, %1
  %9 = add i32 %8, %5
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %10
  %12 = load i16, ptr addrspace(1) %11, align 2, !tbaa !32
  %13 = or disjoint i32 %7, 1
  %14 = mul i32 %13, %1
  %15 = add i32 %14, %5
  %16 = zext i32 %15 to i64
  %17 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %16
  %18 = load i16, ptr addrspace(1) %17, align 2, !tbaa !32
  %19 = or disjoint i32 %7, 2
  %20 = mul i32 %19, %1
  %21 = add i32 %20, %5
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %22
  %24 = load i16, ptr addrspace(1) %23, align 2, !tbaa !32
  %25 = or disjoint i32 %7, 3
  %26 = mul i32 %25, %1
  %27 = add i32 %26, %5
  %28 = zext i32 %27 to i64
  %29 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %28
  %30 = load i16, ptr addrspace(1) %29, align 2, !tbaa !32
  %31 = or disjoint i32 %7, 4
  %32 = mul i32 %31, %1
  %33 = add i32 %32, %5
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %34
  %36 = load i16, ptr addrspace(1) %35, align 2, !tbaa !32
  %37 = or disjoint i32 %7, 5
  %38 = mul i32 %37, %1
  %39 = add i32 %38, %5
  %40 = zext i32 %39 to i64
  %41 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %40
  %42 = load i16, ptr addrspace(1) %41, align 2, !tbaa !32
  %43 = or disjoint i32 %7, 6
  %44 = mul i32 %43, %1
  %45 = add i32 %44, %5
  %46 = zext i32 %45 to i64
  %47 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %46
  %48 = load i16, ptr addrspace(1) %47, align 2, !tbaa !32
  %49 = or disjoint i32 %7, 7
  %50 = mul i32 %49, %1
  %51 = add i32 %50, %5
  %52 = zext i32 %51 to i64
  %53 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %52
  %54 = load i16, ptr addrspace(1) %53, align 2, !tbaa !32
  %55 = insertelement <8 x i16> poison, i16 %12, i64 0
  %56 = insertelement <8 x i16> %55, i16 %18, i64 1
  %57 = insertelement <8 x i16> %56, i16 %24, i64 2
  %58 = insertelement <8 x i16> %57, i16 %30, i64 3
  %59 = insertelement <8 x i16> %58, i16 %36, i64 4
  %60 = insertelement <8 x i16> %59, i16 %42, i64 5
  %61 = insertelement <8 x i16> %60, i16 %48, i64 6
  %62 = insertelement <8 x i16> %61, i16 %54, i64 7
  %63 = zext <8 x i16> %62 to <8 x i32>
  ret <8 x i32> %63
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_b_row_f16_global(i64 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = inttoptr i64 %0 to ptr addrspace(1)
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 1
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 8
  %8 = mul i32 %5, %1
  %9 = add i32 %8, %7
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %10
  %12 = load i16, ptr addrspace(1) %11, align 2, !tbaa !32
  %13 = add i32 %9, 1
  %14 = zext i32 %13 to i64
  %15 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %14
  %16 = load i16, ptr addrspace(1) %15, align 2, !tbaa !32
  %17 = add i32 %9, 2
  %18 = zext i32 %17 to i64
  %19 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %18
  %20 = load i16, ptr addrspace(1) %19, align 2, !tbaa !32
  %21 = add i32 %9, 3
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %22
  %24 = load i16, ptr addrspace(1) %23, align 2, !tbaa !32
  %25 = add i32 %9, 4
  %26 = zext i32 %25 to i64
  %27 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %26
  %28 = load i16, ptr addrspace(1) %27, align 2, !tbaa !32
  %29 = add i32 %9, 5
  %30 = zext i32 %29 to i64
  %31 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %30
  %32 = load i16, ptr addrspace(1) %31, align 2, !tbaa !32
  %33 = add i32 %9, 6
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %34
  %36 = load i16, ptr addrspace(1) %35, align 2, !tbaa !32
  %37 = add i32 %9, 7
  %38 = zext i32 %37 to i64
  %39 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %38
  %40 = load i16, ptr addrspace(1) %39, align 2, !tbaa !32
  %41 = insertelement <8 x i16> poison, i16 %12, i64 0
  %42 = insertelement <8 x i16> %41, i16 %16, i64 1
  %43 = insertelement <8 x i16> %42, i16 %20, i64 2
  %44 = insertelement <8 x i16> %43, i16 %24, i64 3
  %45 = insertelement <8 x i16> %44, i16 %28, i64 4
  %46 = insertelement <8 x i16> %45, i16 %32, i64 5
  %47 = insertelement <8 x i16> %46, i16 %36, i64 6
  %48 = insertelement <8 x i16> %47, i16 %40, i64 7
  %49 = zext <8 x i16> %48 to <8 x i32>
  ret <8 x i32> %49
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_b_col_f16_global(i64 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = inttoptr i64 %0 to ptr addrspace(1)
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 1
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 8
  %8 = mul i32 %7, %1
  %9 = add i32 %8, %5
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %10
  %12 = load i16, ptr addrspace(1) %11, align 2, !tbaa !32
  %13 = or disjoint i32 %7, 1
  %14 = mul i32 %13, %1
  %15 = add i32 %14, %5
  %16 = zext i32 %15 to i64
  %17 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %16
  %18 = load i16, ptr addrspace(1) %17, align 2, !tbaa !32
  %19 = or disjoint i32 %7, 2
  %20 = mul i32 %19, %1
  %21 = add i32 %20, %5
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %22
  %24 = load i16, ptr addrspace(1) %23, align 2, !tbaa !32
  %25 = or disjoint i32 %7, 3
  %26 = mul i32 %25, %1
  %27 = add i32 %26, %5
  %28 = zext i32 %27 to i64
  %29 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %28
  %30 = load i16, ptr addrspace(1) %29, align 2, !tbaa !32
  %31 = or disjoint i32 %7, 4
  %32 = mul i32 %31, %1
  %33 = add i32 %32, %5
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %34
  %36 = load i16, ptr addrspace(1) %35, align 2, !tbaa !32
  %37 = or disjoint i32 %7, 5
  %38 = mul i32 %37, %1
  %39 = add i32 %38, %5
  %40 = zext i32 %39 to i64
  %41 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %40
  %42 = load i16, ptr addrspace(1) %41, align 2, !tbaa !32
  %43 = or disjoint i32 %7, 6
  %44 = mul i32 %43, %1
  %45 = add i32 %44, %5
  %46 = zext i32 %45 to i64
  %47 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %46
  %48 = load i16, ptr addrspace(1) %47, align 2, !tbaa !32
  %49 = or disjoint i32 %7, 7
  %50 = mul i32 %49, %1
  %51 = add i32 %50, %5
  %52 = zext i32 %51 to i64
  %53 = getelementptr inbounds nuw half, ptr addrspace(1) %3, i64 %52
  %54 = load i16, ptr addrspace(1) %53, align 2, !tbaa !32
  %55 = insertelement <8 x i16> poison, i16 %12, i64 0
  %56 = insertelement <8 x i16> %55, i16 %18, i64 1
  %57 = insertelement <8 x i16> %56, i16 %24, i64 2
  %58 = insertelement <8 x i16> %57, i16 %30, i64 3
  %59 = insertelement <8 x i16> %58, i16 %36, i64 4
  %60 = insertelement <8 x i16> %59, i16 %42, i64 5
  %61 = insertelement <8 x i16> %60, i16 %48, i64 6
  %62 = insertelement <8 x i16> %61, i16 %54, i64 7
  %63 = zext <8 x i16> %62 to <8 x i32>
  ret <8 x i32> %63
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_a_row_f16_shared(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = inttoptr i64 %3 to ptr addrspace(3)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = mul i32 %6, %1
  %10 = add i32 %9, %8
  %11 = zext i32 %10 to i64
  %12 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %11
  %13 = load i16, ptr addrspace(3) %12, align 2, !tbaa !32
  %14 = add i32 %10, 1
  %15 = zext i32 %14 to i64
  %16 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %15
  %17 = load i16, ptr addrspace(3) %16, align 2, !tbaa !32
  %18 = add i32 %10, 2
  %19 = zext i32 %18 to i64
  %20 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %19
  %21 = load i16, ptr addrspace(3) %20, align 2, !tbaa !32
  %22 = add i32 %10, 3
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %23
  %25 = load i16, ptr addrspace(3) %24, align 2, !tbaa !32
  %26 = add i32 %10, 4
  %27 = zext i32 %26 to i64
  %28 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %27
  %29 = load i16, ptr addrspace(3) %28, align 2, !tbaa !32
  %30 = add i32 %10, 5
  %31 = zext i32 %30 to i64
  %32 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %31
  %33 = load i16, ptr addrspace(3) %32, align 2, !tbaa !32
  %34 = add i32 %10, 6
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %35
  %37 = load i16, ptr addrspace(3) %36, align 2, !tbaa !32
  %38 = add i32 %10, 7
  %39 = zext i32 %38 to i64
  %40 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %39
  %41 = load i16, ptr addrspace(3) %40, align 2, !tbaa !32
  %42 = insertelement <8 x i16> poison, i16 %13, i64 0
  %43 = insertelement <8 x i16> %42, i16 %17, i64 1
  %44 = insertelement <8 x i16> %43, i16 %21, i64 2
  %45 = insertelement <8 x i16> %44, i16 %25, i64 3
  %46 = insertelement <8 x i16> %45, i16 %29, i64 4
  %47 = insertelement <8 x i16> %46, i16 %33, i64 5
  %48 = insertelement <8 x i16> %47, i16 %37, i64 6
  %49 = insertelement <8 x i16> %48, i16 %41, i64 7
  %50 = zext <8 x i16> %49 to <8 x i32>
  ret <8 x i32> %50
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_a_col_f16_shared(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = inttoptr i64 %3 to ptr addrspace(3)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = mul i32 %8, %1
  %10 = add i32 %9, %6
  %11 = zext i32 %10 to i64
  %12 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %11
  %13 = load i16, ptr addrspace(3) %12, align 2, !tbaa !32
  %14 = or disjoint i32 %8, 1
  %15 = mul i32 %14, %1
  %16 = add i32 %15, %6
  %17 = zext i32 %16 to i64
  %18 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %17
  %19 = load i16, ptr addrspace(3) %18, align 2, !tbaa !32
  %20 = or disjoint i32 %8, 2
  %21 = mul i32 %20, %1
  %22 = add i32 %21, %6
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %23
  %25 = load i16, ptr addrspace(3) %24, align 2, !tbaa !32
  %26 = or disjoint i32 %8, 3
  %27 = mul i32 %26, %1
  %28 = add i32 %27, %6
  %29 = zext i32 %28 to i64
  %30 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %29
  %31 = load i16, ptr addrspace(3) %30, align 2, !tbaa !32
  %32 = or disjoint i32 %8, 4
  %33 = mul i32 %32, %1
  %34 = add i32 %33, %6
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %35
  %37 = load i16, ptr addrspace(3) %36, align 2, !tbaa !32
  %38 = or disjoint i32 %8, 5
  %39 = mul i32 %38, %1
  %40 = add i32 %39, %6
  %41 = zext i32 %40 to i64
  %42 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %41
  %43 = load i16, ptr addrspace(3) %42, align 2, !tbaa !32
  %44 = or disjoint i32 %8, 6
  %45 = mul i32 %44, %1
  %46 = add i32 %45, %6
  %47 = zext i32 %46 to i64
  %48 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %47
  %49 = load i16, ptr addrspace(3) %48, align 2, !tbaa !32
  %50 = or disjoint i32 %8, 7
  %51 = mul i32 %50, %1
  %52 = add i32 %51, %6
  %53 = zext i32 %52 to i64
  %54 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %53
  %55 = load i16, ptr addrspace(3) %54, align 2, !tbaa !32
  %56 = insertelement <8 x i16> poison, i16 %13, i64 0
  %57 = insertelement <8 x i16> %56, i16 %19, i64 1
  %58 = insertelement <8 x i16> %57, i16 %25, i64 2
  %59 = insertelement <8 x i16> %58, i16 %31, i64 3
  %60 = insertelement <8 x i16> %59, i16 %37, i64 4
  %61 = insertelement <8 x i16> %60, i16 %43, i64 5
  %62 = insertelement <8 x i16> %61, i16 %49, i64 6
  %63 = insertelement <8 x i16> %62, i16 %55, i64 7
  %64 = zext <8 x i16> %63 to <8 x i32>
  ret <8 x i32> %64
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_b_row_f16_shared(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = inttoptr i64 %3 to ptr addrspace(3)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = mul i32 %6, %1
  %10 = add i32 %9, %8
  %11 = zext i32 %10 to i64
  %12 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %11
  %13 = load i16, ptr addrspace(3) %12, align 2, !tbaa !32
  %14 = add i32 %10, 1
  %15 = zext i32 %14 to i64
  %16 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %15
  %17 = load i16, ptr addrspace(3) %16, align 2, !tbaa !32
  %18 = add i32 %10, 2
  %19 = zext i32 %18 to i64
  %20 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %19
  %21 = load i16, ptr addrspace(3) %20, align 2, !tbaa !32
  %22 = add i32 %10, 3
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %23
  %25 = load i16, ptr addrspace(3) %24, align 2, !tbaa !32
  %26 = add i32 %10, 4
  %27 = zext i32 %26 to i64
  %28 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %27
  %29 = load i16, ptr addrspace(3) %28, align 2, !tbaa !32
  %30 = add i32 %10, 5
  %31 = zext i32 %30 to i64
  %32 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %31
  %33 = load i16, ptr addrspace(3) %32, align 2, !tbaa !32
  %34 = add i32 %10, 6
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %35
  %37 = load i16, ptr addrspace(3) %36, align 2, !tbaa !32
  %38 = add i32 %10, 7
  %39 = zext i32 %38 to i64
  %40 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %39
  %41 = load i16, ptr addrspace(3) %40, align 2, !tbaa !32
  %42 = insertelement <8 x i16> poison, i16 %13, i64 0
  %43 = insertelement <8 x i16> %42, i16 %17, i64 1
  %44 = insertelement <8 x i16> %43, i16 %21, i64 2
  %45 = insertelement <8 x i16> %44, i16 %25, i64 3
  %46 = insertelement <8 x i16> %45, i16 %29, i64 4
  %47 = insertelement <8 x i16> %46, i16 %33, i64 5
  %48 = insertelement <8 x i16> %47, i16 %37, i64 6
  %49 = insertelement <8 x i16> %48, i16 %41, i64 7
  %50 = zext <8 x i16> %49 to <8 x i32>
  ret <8 x i32> %50
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x i32> @__zluda_ptx_impl_wmma_load_b_col_f16_shared(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = inttoptr i64 %3 to ptr addrspace(3)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = mul i32 %8, %1
  %10 = add i32 %9, %6
  %11 = zext i32 %10 to i64
  %12 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %11
  %13 = load i16, ptr addrspace(3) %12, align 2, !tbaa !32
  %14 = or disjoint i32 %8, 1
  %15 = mul i32 %14, %1
  %16 = add i32 %15, %6
  %17 = zext i32 %16 to i64
  %18 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %17
  %19 = load i16, ptr addrspace(3) %18, align 2, !tbaa !32
  %20 = or disjoint i32 %8, 2
  %21 = mul i32 %20, %1
  %22 = add i32 %21, %6
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %23
  %25 = load i16, ptr addrspace(3) %24, align 2, !tbaa !32
  %26 = or disjoint i32 %8, 3
  %27 = mul i32 %26, %1
  %28 = add i32 %27, %6
  %29 = zext i32 %28 to i64
  %30 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %29
  %31 = load i16, ptr addrspace(3) %30, align 2, !tbaa !32
  %32 = or disjoint i32 %8, 4
  %33 = mul i32 %32, %1
  %34 = add i32 %33, %6
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %35
  %37 = load i16, ptr addrspace(3) %36, align 2, !tbaa !32
  %38 = or disjoint i32 %8, 5
  %39 = mul i32 %38, %1
  %40 = add i32 %39, %6
  %41 = zext i32 %40 to i64
  %42 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %41
  %43 = load i16, ptr addrspace(3) %42, align 2, !tbaa !32
  %44 = or disjoint i32 %8, 6
  %45 = mul i32 %44, %1
  %46 = add i32 %45, %6
  %47 = zext i32 %46 to i64
  %48 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %47
  %49 = load i16, ptr addrspace(3) %48, align 2, !tbaa !32
  %50 = or disjoint i32 %8, 7
  %51 = mul i32 %50, %1
  %52 = add i32 %51, %6
  %53 = zext i32 %52 to i64
  %54 = getelementptr inbounds nuw half, ptr addrspace(3) %4, i64 %53
  %55 = load i16, ptr addrspace(3) %54, align 2, !tbaa !32
  %56 = insertelement <8 x i16> poison, i16 %13, i64 0
  %57 = insertelement <8 x i16> %56, i16 %19, i64 1
  %58 = insertelement <8 x i16> %57, i16 %25, i64 2
  %59 = insertelement <8 x i16> %58, i16 %31, i64 3
  %60 = insertelement <8 x i16> %59, i16 %37, i64 4
  %61 = insertelement <8 x i16> %60, i16 %43, i64 5
  %62 = insertelement <8 x i16> %61, i16 %49, i64 6
  %63 = insertelement <8 x i16> %62, i16 %55, i64 7
  %64 = zext <8 x i16> %63 to <8 x i32>
  ret <8 x i32> %64
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zluda_ptx_impl_wmma_load_c_row_f32_global(i64 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = inttoptr i64 %0 to ptr addrspace(1)
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 1
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 8
  %8 = mul i32 %5, %1
  %9 = add i32 %8, %7
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %10
  %12 = load float, ptr addrspace(1) %11, align 4, !tbaa !29
  %13 = add i32 %9, 1
  %14 = zext i32 %13 to i64
  %15 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %14
  %16 = load float, ptr addrspace(1) %15, align 4, !tbaa !29
  %17 = add i32 %9, 2
  %18 = zext i32 %17 to i64
  %19 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %18
  %20 = load float, ptr addrspace(1) %19, align 4, !tbaa !29
  %21 = add i32 %9, 3
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %22
  %24 = load float, ptr addrspace(1) %23, align 4, !tbaa !29
  %25 = add i32 %9, 4
  %26 = zext i32 %25 to i64
  %27 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %26
  %28 = load float, ptr addrspace(1) %27, align 4, !tbaa !29
  %29 = add i32 %9, 5
  %30 = zext i32 %29 to i64
  %31 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %30
  %32 = load float, ptr addrspace(1) %31, align 4, !tbaa !29
  %33 = add i32 %9, 6
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %34
  %36 = load float, ptr addrspace(1) %35, align 4, !tbaa !29
  %37 = add i32 %9, 7
  %38 = zext i32 %37 to i64
  %39 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %38
  %40 = load float, ptr addrspace(1) %39, align 4, !tbaa !29
  %41 = insertelement <8 x float> poison, float %12, i64 0
  %42 = insertelement <8 x float> %41, float %16, i64 1
  %43 = insertelement <8 x float> %42, float %20, i64 2
  %44 = insertelement <8 x float> %43, float %24, i64 3
  %45 = insertelement <8 x float> %44, float %28, i64 4
  %46 = insertelement <8 x float> %45, float %32, i64 5
  %47 = insertelement <8 x float> %46, float %36, i64 6
  %48 = insertelement <8 x float> %47, float %40, i64 7
  ret <8 x float> %48
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zluda_ptx_impl_wmma_load_c_col_f32_global(i64 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = inttoptr i64 %0 to ptr addrspace(1)
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = lshr i32 %4, 1
  %6 = shl i32 %4, 3
  %7 = and i32 %6, 8
  %8 = mul i32 %7, %1
  %9 = add i32 %8, %5
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %10
  %12 = load float, ptr addrspace(1) %11, align 4, !tbaa !29
  %13 = or disjoint i32 %7, 1
  %14 = mul i32 %13, %1
  %15 = add i32 %14, %5
  %16 = zext i32 %15 to i64
  %17 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %16
  %18 = load float, ptr addrspace(1) %17, align 4, !tbaa !29
  %19 = or disjoint i32 %7, 2
  %20 = mul i32 %19, %1
  %21 = add i32 %20, %5
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %22
  %24 = load float, ptr addrspace(1) %23, align 4, !tbaa !29
  %25 = or disjoint i32 %7, 3
  %26 = mul i32 %25, %1
  %27 = add i32 %26, %5
  %28 = zext i32 %27 to i64
  %29 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %28
  %30 = load float, ptr addrspace(1) %29, align 4, !tbaa !29
  %31 = or disjoint i32 %7, 4
  %32 = mul i32 %31, %1
  %33 = add i32 %32, %5
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %34
  %36 = load float, ptr addrspace(1) %35, align 4, !tbaa !29
  %37 = or disjoint i32 %7, 5
  %38 = mul i32 %37, %1
  %39 = add i32 %38, %5
  %40 = zext i32 %39 to i64
  %41 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %40
  %42 = load float, ptr addrspace(1) %41, align 4, !tbaa !29
  %43 = or disjoint i32 %7, 6
  %44 = mul i32 %43, %1
  %45 = add i32 %44, %5
  %46 = zext i32 %45 to i64
  %47 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %46
  %48 = load float, ptr addrspace(1) %47, align 4, !tbaa !29
  %49 = or disjoint i32 %7, 7
  %50 = mul i32 %49, %1
  %51 = add i32 %50, %5
  %52 = zext i32 %51 to i64
  %53 = getelementptr inbounds nuw float, ptr addrspace(1) %3, i64 %52
  %54 = load float, ptr addrspace(1) %53, align 4, !tbaa !29
  %55 = insertelement <8 x float> poison, float %12, i64 0
  %56 = insertelement <8 x float> %55, float %18, i64 1
  %57 = insertelement <8 x float> %56, float %24, i64 2
  %58 = insertelement <8 x float> %57, float %30, i64 3
  %59 = insertelement <8 x float> %58, float %36, i64 4
  %60 = insertelement <8 x float> %59, float %42, i64 5
  %61 = insertelement <8 x float> %60, float %48, i64 6
  %62 = insertelement <8 x float> %61, float %54, i64 7
  ret <8 x float> %62
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zluda_ptx_impl_wmma_load_c_row_f32_shared(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = inttoptr i64 %3 to ptr addrspace(3)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = mul i32 %6, %1
  %10 = add i32 %9, %8
  %11 = zext i32 %10 to i64
  %12 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %11
  %13 = load float, ptr addrspace(3) %12, align 4, !tbaa !29
  %14 = add i32 %10, 1
  %15 = zext i32 %14 to i64
  %16 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %15
  %17 = load float, ptr addrspace(3) %16, align 4, !tbaa !29
  %18 = add i32 %10, 2
  %19 = zext i32 %18 to i64
  %20 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %19
  %21 = load float, ptr addrspace(3) %20, align 4, !tbaa !29
  %22 = add i32 %10, 3
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %23
  %25 = load float, ptr addrspace(3) %24, align 4, !tbaa !29
  %26 = add i32 %10, 4
  %27 = zext i32 %26 to i64
  %28 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %27
  %29 = load float, ptr addrspace(3) %28, align 4, !tbaa !29
  %30 = add i32 %10, 5
  %31 = zext i32 %30 to i64
  %32 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %31
  %33 = load float, ptr addrspace(3) %32, align 4, !tbaa !29
  %34 = add i32 %10, 6
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %35
  %37 = load float, ptr addrspace(3) %36, align 4, !tbaa !29
  %38 = add i32 %10, 7
  %39 = zext i32 %38 to i64
  %40 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %39
  %41 = load float, ptr addrspace(3) %40, align 4, !tbaa !29
  %42 = insertelement <8 x float> poison, float %13, i64 0
  %43 = insertelement <8 x float> %42, float %17, i64 1
  %44 = insertelement <8 x float> %43, float %21, i64 2
  %45 = insertelement <8 x float> %44, float %25, i64 3
  %46 = insertelement <8 x float> %45, float %29, i64 4
  %47 = insertelement <8 x float> %46, float %33, i64 5
  %48 = insertelement <8 x float> %47, float %37, i64 6
  %49 = insertelement <8 x float> %48, float %41, i64 7
  ret <8 x float> %49
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zluda_ptx_impl_wmma_load_c_col_f32_shared(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = inttoptr i64 %3 to ptr addrspace(3)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = mul i32 %8, %1
  %10 = add i32 %9, %6
  %11 = zext i32 %10 to i64
  %12 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %11
  %13 = load float, ptr addrspace(3) %12, align 4, !tbaa !29
  %14 = or disjoint i32 %8, 1
  %15 = mul i32 %14, %1
  %16 = add i32 %15, %6
  %17 = zext i32 %16 to i64
  %18 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %17
  %19 = load float, ptr addrspace(3) %18, align 4, !tbaa !29
  %20 = or disjoint i32 %8, 2
  %21 = mul i32 %20, %1
  %22 = add i32 %21, %6
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %23
  %25 = load float, ptr addrspace(3) %24, align 4, !tbaa !29
  %26 = or disjoint i32 %8, 3
  %27 = mul i32 %26, %1
  %28 = add i32 %27, %6
  %29 = zext i32 %28 to i64
  %30 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %29
  %31 = load float, ptr addrspace(3) %30, align 4, !tbaa !29
  %32 = or disjoint i32 %8, 4
  %33 = mul i32 %32, %1
  %34 = add i32 %33, %6
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %35
  %37 = load float, ptr addrspace(3) %36, align 4, !tbaa !29
  %38 = or disjoint i32 %8, 5
  %39 = mul i32 %38, %1
  %40 = add i32 %39, %6
  %41 = zext i32 %40 to i64
  %42 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %41
  %43 = load float, ptr addrspace(3) %42, align 4, !tbaa !29
  %44 = or disjoint i32 %8, 6
  %45 = mul i32 %44, %1
  %46 = add i32 %45, %6
  %47 = zext i32 %46 to i64
  %48 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %47
  %49 = load float, ptr addrspace(3) %48, align 4, !tbaa !29
  %50 = or disjoint i32 %8, 7
  %51 = mul i32 %50, %1
  %52 = add i32 %51, %6
  %53 = zext i32 %52 to i64
  %54 = getelementptr inbounds nuw float, ptr addrspace(3) %4, i64 %53
  %55 = load float, ptr addrspace(3) %54, align 4, !tbaa !29
  %56 = insertelement <8 x float> poison, float %13, i64 0
  %57 = insertelement <8 x float> %56, float %19, i64 1
  %58 = insertelement <8 x float> %57, float %25, i64 2
  %59 = insertelement <8 x float> %58, float %31, i64 3
  %60 = insertelement <8 x float> %59, float %37, i64 4
  %61 = insertelement <8 x float> %60, float %43, i64 5
  %62 = insertelement <8 x float> %61, float %49, i64 6
  %63 = insertelement <8 x float> %62, float %55, i64 7
  ret <8 x float> %63
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zluda_ptx_impl_wmma_store_d_row_f32_global(i64 noundef %0, <8 x float> noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = inttoptr i64 %0 to ptr addrspace(1)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = extractelement <8 x float> %1, i64 0
  %10 = extractelement <8 x float> %1, i64 1
  %11 = extractelement <8 x float> %1, i64 2
  %12 = extractelement <8 x float> %1, i64 3
  %13 = extractelement <8 x float> %1, i64 4
  %14 = extractelement <8 x float> %1, i64 5
  %15 = extractelement <8 x float> %1, i64 6
  %16 = extractelement <8 x float> %1, i64 7
  %17 = mul i32 %6, %2
  %18 = add i32 %17, %8
  %19 = zext i32 %18 to i64
  %20 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %19
  store float %9, ptr addrspace(1) %20, align 4, !tbaa !29
  %21 = add i32 %18, 1
  %22 = zext i32 %21 to i64
  %23 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %22
  store float %10, ptr addrspace(1) %23, align 4, !tbaa !29
  %24 = add i32 %18, 2
  %25 = zext i32 %24 to i64
  %26 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %25
  store float %11, ptr addrspace(1) %26, align 4, !tbaa !29
  %27 = add i32 %18, 3
  %28 = zext i32 %27 to i64
  %29 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %28
  store float %12, ptr addrspace(1) %29, align 4, !tbaa !29
  %30 = add i32 %18, 4
  %31 = zext i32 %30 to i64
  %32 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %31
  store float %13, ptr addrspace(1) %32, align 4, !tbaa !29
  %33 = add i32 %18, 5
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %34
  store float %14, ptr addrspace(1) %35, align 4, !tbaa !29
  %36 = add i32 %18, 6
  %37 = zext i32 %36 to i64
  %38 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %37
  store float %15, ptr addrspace(1) %38, align 4, !tbaa !29
  %39 = add i32 %18, 7
  %40 = zext i32 %39 to i64
  %41 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %40
  store float %16, ptr addrspace(1) %41, align 4, !tbaa !29
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zluda_ptx_impl_wmma_store_d_col_f32_global(i64 noundef %0, <8 x float> noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = inttoptr i64 %0 to ptr addrspace(1)
  %5 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %6 = lshr i32 %5, 1
  %7 = shl i32 %5, 3
  %8 = and i32 %7, 8
  %9 = extractelement <8 x float> %1, i64 0
  %10 = extractelement <8 x float> %1, i64 1
  %11 = extractelement <8 x float> %1, i64 2
  %12 = extractelement <8 x float> %1, i64 3
  %13 = extractelement <8 x float> %1, i64 4
  %14 = extractelement <8 x float> %1, i64 5
  %15 = extractelement <8 x float> %1, i64 6
  %16 = extractelement <8 x float> %1, i64 7
  %17 = mul i32 %8, %2
  %18 = add i32 %17, %6
  %19 = zext i32 %18 to i64
  %20 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %19
  store float %9, ptr addrspace(1) %20, align 4, !tbaa !29
  %21 = or disjoint i32 %8, 1
  %22 = mul i32 %21, %2
  %23 = add i32 %22, %6
  %24 = zext i32 %23 to i64
  %25 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %24
  store float %10, ptr addrspace(1) %25, align 4, !tbaa !29
  %26 = or disjoint i32 %8, 2
  %27 = mul i32 %26, %2
  %28 = add i32 %27, %6
  %29 = zext i32 %28 to i64
  %30 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %29
  store float %11, ptr addrspace(1) %30, align 4, !tbaa !29
  %31 = or disjoint i32 %8, 3
  %32 = mul i32 %31, %2
  %33 = add i32 %32, %6
  %34 = zext i32 %33 to i64
  %35 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %34
  store float %12, ptr addrspace(1) %35, align 4, !tbaa !29
  %36 = or disjoint i32 %8, 4
  %37 = mul i32 %36, %2
  %38 = add i32 %37, %6
  %39 = zext i32 %38 to i64
  %40 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %39
  store float %13, ptr addrspace(1) %40, align 4, !tbaa !29
  %41 = or disjoint i32 %8, 5
  %42 = mul i32 %41, %2
  %43 = add i32 %42, %6
  %44 = zext i32 %43 to i64
  %45 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %44
  store float %14, ptr addrspace(1) %45, align 4, !tbaa !29
  %46 = or disjoint i32 %8, 6
  %47 = mul i32 %46, %2
  %48 = add i32 %47, %6
  %49 = zext i32 %48 to i64
  %50 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %49
  store float %15, ptr addrspace(1) %50, align 4, !tbaa !29
  %51 = or disjoint i32 %8, 7
  %52 = mul i32 %51, %2
  %53 = add i32 %52, %6
  %54 = zext i32 %53 to i64
  %55 = getelementptr inbounds nuw float, ptr addrspace(1) %4, i64 %54
  store float %16, ptr addrspace(1) %55, align 4, !tbaa !29
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zluda_ptx_impl_wmma_store_d_row_f32_shared(i32 noundef %0, <8 x float> noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = zext i32 %0 to i64
  %5 = inttoptr i64 %4 to ptr addrspace(3)
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = lshr i32 %6, 1
  %8 = shl i32 %6, 3
  %9 = and i32 %8, 8
  %10 = extractelement <8 x float> %1, i64 0
  %11 = extractelement <8 x float> %1, i64 1
  %12 = extractelement <8 x float> %1, i64 2
  %13 = extractelement <8 x float> %1, i64 3
  %14 = extractelement <8 x float> %1, i64 4
  %15 = extractelement <8 x float> %1, i64 5
  %16 = extractelement <8 x float> %1, i64 6
  %17 = extractelement <8 x float> %1, i64 7
  %18 = mul i32 %7, %2
  %19 = add i32 %18, %9
  %20 = zext i32 %19 to i64
  %21 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %20
  store float %10, ptr addrspace(3) %21, align 4, !tbaa !29
  %22 = add i32 %19, 1
  %23 = zext i32 %22 to i64
  %24 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %23
  store float %11, ptr addrspace(3) %24, align 4, !tbaa !29
  %25 = add i32 %19, 2
  %26 = zext i32 %25 to i64
  %27 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %26
  store float %12, ptr addrspace(3) %27, align 4, !tbaa !29
  %28 = add i32 %19, 3
  %29 = zext i32 %28 to i64
  %30 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %29
  store float %13, ptr addrspace(3) %30, align 4, !tbaa !29
  %31 = add i32 %19, 4
  %32 = zext i32 %31 to i64
  %33 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %32
  store float %14, ptr addrspace(3) %33, align 4, !tbaa !29
  %34 = add i32 %19, 5
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %35
  store float %15, ptr addrspace(3) %36, align 4, !tbaa !29
  %37 = add i32 %19, 6
  %38 = zext i32 %37 to i64
  %39 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %38
  store float %16, ptr addrspace(3) %39, align 4, !tbaa !29
  %40 = add i32 %19, 7
  %41 = zext i32 %40 to i64
  %42 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %41
  store float %17, ptr addrspace(3) %42, align 4, !tbaa !29
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func void @__zluda_ptx_impl_wmma_store_d_col_f32_shared(i32 noundef %0, <8 x float> noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = zext i32 %0 to i64
  %5 = inttoptr i64 %4 to ptr addrspace(3)
  %6 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %7 = lshr i32 %6, 1
  %8 = shl i32 %6, 3
  %9 = and i32 %8, 8
  %10 = extractelement <8 x float> %1, i64 0
  %11 = extractelement <8 x float> %1, i64 1
  %12 = extractelement <8 x float> %1, i64 2
  %13 = extractelement <8 x float> %1, i64 3
  %14 = extractelement <8 x float> %1, i64 4
  %15 = extractelement <8 x float> %1, i64 5
  %16 = extractelement <8 x float> %1, i64 6
  %17 = extractelement <8 x float> %1, i64 7
  %18 = mul i32 %9, %2
  %19 = add i32 %18, %7
  %20 = zext i32 %19 to i64
  %21 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %20
  store float %10, ptr addrspace(3) %21, align 4, !tbaa !29
  %22 = or disjoint i32 %9, 1
  %23 = mul i32 %22, %2
  %24 = add i32 %23, %7
  %25 = zext i32 %24 to i64
  %26 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %25
  store float %11, ptr addrspace(3) %26, align 4, !tbaa !29
  %27 = or disjoint i32 %9, 2
  %28 = mul i32 %27, %2
  %29 = add i32 %28, %7
  %30 = zext i32 %29 to i64
  %31 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %30
  store float %12, ptr addrspace(3) %31, align 4, !tbaa !29
  %32 = or disjoint i32 %9, 3
  %33 = mul i32 %32, %2
  %34 = add i32 %33, %7
  %35 = zext i32 %34 to i64
  %36 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %35
  store float %13, ptr addrspace(3) %36, align 4, !tbaa !29
  %37 = or disjoint i32 %9, 4
  %38 = mul i32 %37, %2
  %39 = add i32 %38, %7
  %40 = zext i32 %39 to i64
  %41 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %40
  store float %14, ptr addrspace(3) %41, align 4, !tbaa !29
  %42 = or disjoint i32 %9, 5
  %43 = mul i32 %42, %2
  %44 = add i32 %43, %7
  %45 = zext i32 %44 to i64
  %46 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %45
  store float %15, ptr addrspace(3) %46, align 4, !tbaa !29
  %47 = or disjoint i32 %9, 6
  %48 = mul i32 %47, %2
  %49 = add i32 %48, %7
  %50 = zext i32 %49 to i64
  %51 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %50
  store float %16, ptr addrspace(3) %51, align 4, !tbaa !29
  %52 = or disjoint i32 %9, 7
  %53 = mul i32 %52, %2
  %54 = add i32 %53, %7
  %55 = zext i32 %54 to i64
  %56 = getelementptr inbounds nuw float, ptr addrspace(3) %5, i64 %55
  store float %17, ptr addrspace(3) %56, align 4, !tbaa !29
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind
define linkonce_odr spir_func <8 x float> @__zluda_ptx_impl_wmma_mma_row_col_f32_f32(<8 x i32> noundef %0, <8 x i32> noundef %1, <8 x float> noundef %2) local_unnamed_addr #0 {
  %4 = tail call spir_func i32 @_Z22get_sub_group_local_idv() #10
  %5 = extractelement <8 x i32> %0, i64 0
  %6 = extractelement <8 x i32> %0, i64 1
  %7 = extractelement <8 x i32> %0, i64 2
  %8 = extractelement <8 x i32> %0, i64 3
  %9 = extractelement <8 x i32> %0, i64 4
  %10 = extractelement <8 x i32> %0, i64 5
  %11 = extractelement <8 x i32> %0, i64 6
  %12 = extractelement <8 x i32> %0, i64 7
  %13 = extractelement <8 x i32> %1, i64 0
  %14 = extractelement <8 x i32> %1, i64 1
  %15 = extractelement <8 x i32> %1, i64 2
  %16 = extractelement <8 x i32> %1, i64 3
  %17 = extractelement <8 x i32> %1, i64 4
  %18 = extractelement <8 x i32> %1, i64 5
  %19 = extractelement <8 x i32> %1, i64 6
  %20 = extractelement <8 x i32> %1, i64 7
  %21 = extractelement <8 x float> %2, i64 0
  %22 = extractelement <8 x float> %2, i64 1
  %23 = extractelement <8 x float> %2, i64 2
  %24 = extractelement <8 x float> %2, i64 3
  %25 = extractelement <8 x float> %2, i64 4
  %26 = extractelement <8 x float> %2, i64 5
  %27 = extractelement <8 x float> %2, i64 6
  %28 = extractelement <8 x float> %2, i64 7
  %29 = and i32 %4, -2
  %30 = and i32 %4, 1
  %31 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %5, i32 noundef %29) #10
  %32 = trunc i32 %31 to i16
  %33 = bitcast i16 %32 to half
  %34 = fpext half %33 to float
  %35 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %30) #10
  %36 = trunc i32 %35 to i16
  %37 = bitcast i16 %36 to half
  %38 = fpext half %37 to float
  %39 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %38, float noundef %21) #11
  %40 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %30) #10
  %41 = trunc i32 %40 to i16
  %42 = bitcast i16 %41 to half
  %43 = fpext half %42 to float
  %44 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %43, float noundef %22) #11
  %45 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %30) #10
  %46 = trunc i32 %45 to i16
  %47 = bitcast i16 %46 to half
  %48 = fpext half %47 to float
  %49 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %48, float noundef %23) #11
  %50 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %30) #10
  %51 = trunc i32 %50 to i16
  %52 = bitcast i16 %51 to half
  %53 = fpext half %52 to float
  %54 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %53, float noundef %24) #11
  %55 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %30) #10
  %56 = trunc i32 %55 to i16
  %57 = bitcast i16 %56 to half
  %58 = fpext half %57 to float
  %59 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %58, float noundef %25) #11
  %60 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %30) #10
  %61 = trunc i32 %60 to i16
  %62 = bitcast i16 %61 to half
  %63 = fpext half %62 to float
  %64 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %63, float noundef %26) #11
  %65 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %30) #10
  %66 = trunc i32 %65 to i16
  %67 = bitcast i16 %66 to half
  %68 = fpext half %67 to float
  %69 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %68, float noundef %27) #11
  %70 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %30) #10
  %71 = trunc i32 %70 to i16
  %72 = bitcast i16 %71 to half
  %73 = fpext half %72 to float
  %74 = tail call spir_func float @_Z3fmafff(float noundef %34, float noundef %73, float noundef %28) #11
  %75 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %6, i32 noundef %29) #10
  %76 = trunc i32 %75 to i16
  %77 = bitcast i16 %76 to half
  %78 = fpext half %77 to float
  %79 = or disjoint i32 %30, 2
  %80 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %79) #10
  %81 = trunc i32 %80 to i16
  %82 = bitcast i16 %81 to half
  %83 = fpext half %82 to float
  %84 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %83, float noundef %39) #11
  %85 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %79) #10
  %86 = trunc i32 %85 to i16
  %87 = bitcast i16 %86 to half
  %88 = fpext half %87 to float
  %89 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %88, float noundef %44) #11
  %90 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %79) #10
  %91 = trunc i32 %90 to i16
  %92 = bitcast i16 %91 to half
  %93 = fpext half %92 to float
  %94 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %93, float noundef %49) #11
  %95 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %79) #10
  %96 = trunc i32 %95 to i16
  %97 = bitcast i16 %96 to half
  %98 = fpext half %97 to float
  %99 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %98, float noundef %54) #11
  %100 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %79) #10
  %101 = trunc i32 %100 to i16
  %102 = bitcast i16 %101 to half
  %103 = fpext half %102 to float
  %104 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %103, float noundef %59) #11
  %105 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %79) #10
  %106 = trunc i32 %105 to i16
  %107 = bitcast i16 %106 to half
  %108 = fpext half %107 to float
  %109 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %108, float noundef %64) #11
  %110 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %79) #10
  %111 = trunc i32 %110 to i16
  %112 = bitcast i16 %111 to half
  %113 = fpext half %112 to float
  %114 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %113, float noundef %69) #11
  %115 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %79) #10
  %116 = trunc i32 %115 to i16
  %117 = bitcast i16 %116 to half
  %118 = fpext half %117 to float
  %119 = tail call spir_func float @_Z3fmafff(float noundef %78, float noundef %118, float noundef %74) #11
  %120 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %7, i32 noundef %29) #10
  %121 = trunc i32 %120 to i16
  %122 = bitcast i16 %121 to half
  %123 = fpext half %122 to float
  %124 = or disjoint i32 %30, 4
  %125 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %124) #10
  %126 = trunc i32 %125 to i16
  %127 = bitcast i16 %126 to half
  %128 = fpext half %127 to float
  %129 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %128, float noundef %84) #11
  %130 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %124) #10
  %131 = trunc i32 %130 to i16
  %132 = bitcast i16 %131 to half
  %133 = fpext half %132 to float
  %134 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %133, float noundef %89) #11
  %135 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %124) #10
  %136 = trunc i32 %135 to i16
  %137 = bitcast i16 %136 to half
  %138 = fpext half %137 to float
  %139 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %138, float noundef %94) #11
  %140 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %124) #10
  %141 = trunc i32 %140 to i16
  %142 = bitcast i16 %141 to half
  %143 = fpext half %142 to float
  %144 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %143, float noundef %99) #11
  %145 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %124) #10
  %146 = trunc i32 %145 to i16
  %147 = bitcast i16 %146 to half
  %148 = fpext half %147 to float
  %149 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %148, float noundef %104) #11
  %150 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %124) #10
  %151 = trunc i32 %150 to i16
  %152 = bitcast i16 %151 to half
  %153 = fpext half %152 to float
  %154 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %153, float noundef %109) #11
  %155 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %124) #10
  %156 = trunc i32 %155 to i16
  %157 = bitcast i16 %156 to half
  %158 = fpext half %157 to float
  %159 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %158, float noundef %114) #11
  %160 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %124) #10
  %161 = trunc i32 %160 to i16
  %162 = bitcast i16 %161 to half
  %163 = fpext half %162 to float
  %164 = tail call spir_func float @_Z3fmafff(float noundef %123, float noundef %163, float noundef %119) #11
  %165 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %8, i32 noundef %29) #10
  %166 = trunc i32 %165 to i16
  %167 = bitcast i16 %166 to half
  %168 = fpext half %167 to float
  %169 = or disjoint i32 %30, 6
  %170 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %169) #10
  %171 = trunc i32 %170 to i16
  %172 = bitcast i16 %171 to half
  %173 = fpext half %172 to float
  %174 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %173, float noundef %129) #11
  %175 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %169) #10
  %176 = trunc i32 %175 to i16
  %177 = bitcast i16 %176 to half
  %178 = fpext half %177 to float
  %179 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %178, float noundef %134) #11
  %180 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %169) #10
  %181 = trunc i32 %180 to i16
  %182 = bitcast i16 %181 to half
  %183 = fpext half %182 to float
  %184 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %183, float noundef %139) #11
  %185 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %169) #10
  %186 = trunc i32 %185 to i16
  %187 = bitcast i16 %186 to half
  %188 = fpext half %187 to float
  %189 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %188, float noundef %144) #11
  %190 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %169) #10
  %191 = trunc i32 %190 to i16
  %192 = bitcast i16 %191 to half
  %193 = fpext half %192 to float
  %194 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %193, float noundef %149) #11
  %195 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %169) #10
  %196 = trunc i32 %195 to i16
  %197 = bitcast i16 %196 to half
  %198 = fpext half %197 to float
  %199 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %198, float noundef %154) #11
  %200 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %169) #10
  %201 = trunc i32 %200 to i16
  %202 = bitcast i16 %201 to half
  %203 = fpext half %202 to float
  %204 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %203, float noundef %159) #11
  %205 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %169) #10
  %206 = trunc i32 %205 to i16
  %207 = bitcast i16 %206 to half
  %208 = fpext half %207 to float
  %209 = tail call spir_func float @_Z3fmafff(float noundef %168, float noundef %208, float noundef %164) #11
  %210 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %9, i32 noundef %29) #10
  %211 = trunc i32 %210 to i16
  %212 = bitcast i16 %211 to half
  %213 = fpext half %212 to float
  %214 = or disjoint i32 %30, 8
  %215 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %214) #10
  %216 = trunc i32 %215 to i16
  %217 = bitcast i16 %216 to half
  %218 = fpext half %217 to float
  %219 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %218, float noundef %174) #11
  %220 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %214) #10
  %221 = trunc i32 %220 to i16
  %222 = bitcast i16 %221 to half
  %223 = fpext half %222 to float
  %224 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %223, float noundef %179) #11
  %225 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %214) #10
  %226 = trunc i32 %225 to i16
  %227 = bitcast i16 %226 to half
  %228 = fpext half %227 to float
  %229 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %228, float noundef %184) #11
  %230 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %214) #10
  %231 = trunc i32 %230 to i16
  %232 = bitcast i16 %231 to half
  %233 = fpext half %232 to float
  %234 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %233, float noundef %189) #11
  %235 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %214) #10
  %236 = trunc i32 %235 to i16
  %237 = bitcast i16 %236 to half
  %238 = fpext half %237 to float
  %239 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %238, float noundef %194) #11
  %240 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %214) #10
  %241 = trunc i32 %240 to i16
  %242 = bitcast i16 %241 to half
  %243 = fpext half %242 to float
  %244 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %243, float noundef %199) #11
  %245 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %214) #10
  %246 = trunc i32 %245 to i16
  %247 = bitcast i16 %246 to half
  %248 = fpext half %247 to float
  %249 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %248, float noundef %204) #11
  %250 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %214) #10
  %251 = trunc i32 %250 to i16
  %252 = bitcast i16 %251 to half
  %253 = fpext half %252 to float
  %254 = tail call spir_func float @_Z3fmafff(float noundef %213, float noundef %253, float noundef %209) #11
  %255 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %10, i32 noundef %29) #10
  %256 = trunc i32 %255 to i16
  %257 = bitcast i16 %256 to half
  %258 = fpext half %257 to float
  %259 = or disjoint i32 %30, 10
  %260 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %259) #10
  %261 = trunc i32 %260 to i16
  %262 = bitcast i16 %261 to half
  %263 = fpext half %262 to float
  %264 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %263, float noundef %219) #11
  %265 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %259) #10
  %266 = trunc i32 %265 to i16
  %267 = bitcast i16 %266 to half
  %268 = fpext half %267 to float
  %269 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %268, float noundef %224) #11
  %270 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %259) #10
  %271 = trunc i32 %270 to i16
  %272 = bitcast i16 %271 to half
  %273 = fpext half %272 to float
  %274 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %273, float noundef %229) #11
  %275 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %259) #10
  %276 = trunc i32 %275 to i16
  %277 = bitcast i16 %276 to half
  %278 = fpext half %277 to float
  %279 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %278, float noundef %234) #11
  %280 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %259) #10
  %281 = trunc i32 %280 to i16
  %282 = bitcast i16 %281 to half
  %283 = fpext half %282 to float
  %284 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %283, float noundef %239) #11
  %285 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %259) #10
  %286 = trunc i32 %285 to i16
  %287 = bitcast i16 %286 to half
  %288 = fpext half %287 to float
  %289 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %288, float noundef %244) #11
  %290 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %259) #10
  %291 = trunc i32 %290 to i16
  %292 = bitcast i16 %291 to half
  %293 = fpext half %292 to float
  %294 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %293, float noundef %249) #11
  %295 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %259) #10
  %296 = trunc i32 %295 to i16
  %297 = bitcast i16 %296 to half
  %298 = fpext half %297 to float
  %299 = tail call spir_func float @_Z3fmafff(float noundef %258, float noundef %298, float noundef %254) #11
  %300 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %11, i32 noundef %29) #10
  %301 = trunc i32 %300 to i16
  %302 = bitcast i16 %301 to half
  %303 = fpext half %302 to float
  %304 = or disjoint i32 %30, 12
  %305 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %304) #10
  %306 = trunc i32 %305 to i16
  %307 = bitcast i16 %306 to half
  %308 = fpext half %307 to float
  %309 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %308, float noundef %264) #11
  %310 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %304) #10
  %311 = trunc i32 %310 to i16
  %312 = bitcast i16 %311 to half
  %313 = fpext half %312 to float
  %314 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %313, float noundef %269) #11
  %315 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %304) #10
  %316 = trunc i32 %315 to i16
  %317 = bitcast i16 %316 to half
  %318 = fpext half %317 to float
  %319 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %318, float noundef %274) #11
  %320 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %304) #10
  %321 = trunc i32 %320 to i16
  %322 = bitcast i16 %321 to half
  %323 = fpext half %322 to float
  %324 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %323, float noundef %279) #11
  %325 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %304) #10
  %326 = trunc i32 %325 to i16
  %327 = bitcast i16 %326 to half
  %328 = fpext half %327 to float
  %329 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %328, float noundef %284) #11
  %330 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %304) #10
  %331 = trunc i32 %330 to i16
  %332 = bitcast i16 %331 to half
  %333 = fpext half %332 to float
  %334 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %333, float noundef %289) #11
  %335 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %304) #10
  %336 = trunc i32 %335 to i16
  %337 = bitcast i16 %336 to half
  %338 = fpext half %337 to float
  %339 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %338, float noundef %294) #11
  %340 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %304) #10
  %341 = trunc i32 %340 to i16
  %342 = bitcast i16 %341 to half
  %343 = fpext half %342 to float
  %344 = tail call spir_func float @_Z3fmafff(float noundef %303, float noundef %343, float noundef %299) #11
  %345 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %12, i32 noundef %29) #10
  %346 = trunc i32 %345 to i16
  %347 = bitcast i16 %346 to half
  %348 = fpext half %347 to float
  %349 = or disjoint i32 %30, 14
  %350 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %349) #10
  %351 = trunc i32 %350 to i16
  %352 = bitcast i16 %351 to half
  %353 = fpext half %352 to float
  %354 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %353, float noundef %309) #11
  %355 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %349) #10
  %356 = trunc i32 %355 to i16
  %357 = bitcast i16 %356 to half
  %358 = fpext half %357 to float
  %359 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %358, float noundef %314) #11
  %360 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %349) #10
  %361 = trunc i32 %360 to i16
  %362 = bitcast i16 %361 to half
  %363 = fpext half %362 to float
  %364 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %363, float noundef %319) #11
  %365 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %349) #10
  %366 = trunc i32 %365 to i16
  %367 = bitcast i16 %366 to half
  %368 = fpext half %367 to float
  %369 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %368, float noundef %324) #11
  %370 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %349) #10
  %371 = trunc i32 %370 to i16
  %372 = bitcast i16 %371 to half
  %373 = fpext half %372 to float
  %374 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %373, float noundef %329) #11
  %375 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %349) #10
  %376 = trunc i32 %375 to i16
  %377 = bitcast i16 %376 to half
  %378 = fpext half %377 to float
  %379 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %378, float noundef %334) #11
  %380 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %349) #10
  %381 = trunc i32 %380 to i16
  %382 = bitcast i16 %381 to half
  %383 = fpext half %382 to float
  %384 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %383, float noundef %339) #11
  %385 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %349) #10
  %386 = trunc i32 %385 to i16
  %387 = bitcast i16 %386 to half
  %388 = fpext half %387 to float
  %389 = tail call spir_func float @_Z3fmafff(float noundef %348, float noundef %388, float noundef %344) #11
  %390 = or i32 %4, 1
  %391 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %5, i32 noundef %390) #10
  %392 = trunc i32 %391 to i16
  %393 = bitcast i16 %392 to half
  %394 = fpext half %393 to float
  %395 = or disjoint i32 %30, 16
  %396 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %395) #10
  %397 = trunc i32 %396 to i16
  %398 = bitcast i16 %397 to half
  %399 = fpext half %398 to float
  %400 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %399, float noundef %354) #11
  %401 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %395) #10
  %402 = trunc i32 %401 to i16
  %403 = bitcast i16 %402 to half
  %404 = fpext half %403 to float
  %405 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %404, float noundef %359) #11
  %406 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %395) #10
  %407 = trunc i32 %406 to i16
  %408 = bitcast i16 %407 to half
  %409 = fpext half %408 to float
  %410 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %409, float noundef %364) #11
  %411 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %395) #10
  %412 = trunc i32 %411 to i16
  %413 = bitcast i16 %412 to half
  %414 = fpext half %413 to float
  %415 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %414, float noundef %369) #11
  %416 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %395) #10
  %417 = trunc i32 %416 to i16
  %418 = bitcast i16 %417 to half
  %419 = fpext half %418 to float
  %420 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %419, float noundef %374) #11
  %421 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %395) #10
  %422 = trunc i32 %421 to i16
  %423 = bitcast i16 %422 to half
  %424 = fpext half %423 to float
  %425 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %424, float noundef %379) #11
  %426 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %395) #10
  %427 = trunc i32 %426 to i16
  %428 = bitcast i16 %427 to half
  %429 = fpext half %428 to float
  %430 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %429, float noundef %384) #11
  %431 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %395) #10
  %432 = trunc i32 %431 to i16
  %433 = bitcast i16 %432 to half
  %434 = fpext half %433 to float
  %435 = tail call spir_func float @_Z3fmafff(float noundef %394, float noundef %434, float noundef %389) #11
  %436 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %6, i32 noundef %390) #10
  %437 = trunc i32 %436 to i16
  %438 = bitcast i16 %437 to half
  %439 = fpext half %438 to float
  %440 = or disjoint i32 %30, 18
  %441 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %440) #10
  %442 = trunc i32 %441 to i16
  %443 = bitcast i16 %442 to half
  %444 = fpext half %443 to float
  %445 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %444, float noundef %400) #11
  %446 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %440) #10
  %447 = trunc i32 %446 to i16
  %448 = bitcast i16 %447 to half
  %449 = fpext half %448 to float
  %450 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %449, float noundef %405) #11
  %451 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %440) #10
  %452 = trunc i32 %451 to i16
  %453 = bitcast i16 %452 to half
  %454 = fpext half %453 to float
  %455 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %454, float noundef %410) #11
  %456 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %440) #10
  %457 = trunc i32 %456 to i16
  %458 = bitcast i16 %457 to half
  %459 = fpext half %458 to float
  %460 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %459, float noundef %415) #11
  %461 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %440) #10
  %462 = trunc i32 %461 to i16
  %463 = bitcast i16 %462 to half
  %464 = fpext half %463 to float
  %465 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %464, float noundef %420) #11
  %466 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %440) #10
  %467 = trunc i32 %466 to i16
  %468 = bitcast i16 %467 to half
  %469 = fpext half %468 to float
  %470 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %469, float noundef %425) #11
  %471 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %440) #10
  %472 = trunc i32 %471 to i16
  %473 = bitcast i16 %472 to half
  %474 = fpext half %473 to float
  %475 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %474, float noundef %430) #11
  %476 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %440) #10
  %477 = trunc i32 %476 to i16
  %478 = bitcast i16 %477 to half
  %479 = fpext half %478 to float
  %480 = tail call spir_func float @_Z3fmafff(float noundef %439, float noundef %479, float noundef %435) #11
  %481 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %7, i32 noundef %390) #10
  %482 = trunc i32 %481 to i16
  %483 = bitcast i16 %482 to half
  %484 = fpext half %483 to float
  %485 = or disjoint i32 %30, 20
  %486 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %485) #10
  %487 = trunc i32 %486 to i16
  %488 = bitcast i16 %487 to half
  %489 = fpext half %488 to float
  %490 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %489, float noundef %445) #11
  %491 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %485) #10
  %492 = trunc i32 %491 to i16
  %493 = bitcast i16 %492 to half
  %494 = fpext half %493 to float
  %495 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %494, float noundef %450) #11
  %496 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %485) #10
  %497 = trunc i32 %496 to i16
  %498 = bitcast i16 %497 to half
  %499 = fpext half %498 to float
  %500 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %499, float noundef %455) #11
  %501 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %485) #10
  %502 = trunc i32 %501 to i16
  %503 = bitcast i16 %502 to half
  %504 = fpext half %503 to float
  %505 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %504, float noundef %460) #11
  %506 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %485) #10
  %507 = trunc i32 %506 to i16
  %508 = bitcast i16 %507 to half
  %509 = fpext half %508 to float
  %510 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %509, float noundef %465) #11
  %511 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %485) #10
  %512 = trunc i32 %511 to i16
  %513 = bitcast i16 %512 to half
  %514 = fpext half %513 to float
  %515 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %514, float noundef %470) #11
  %516 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %485) #10
  %517 = trunc i32 %516 to i16
  %518 = bitcast i16 %517 to half
  %519 = fpext half %518 to float
  %520 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %519, float noundef %475) #11
  %521 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %485) #10
  %522 = trunc i32 %521 to i16
  %523 = bitcast i16 %522 to half
  %524 = fpext half %523 to float
  %525 = tail call spir_func float @_Z3fmafff(float noundef %484, float noundef %524, float noundef %480) #11
  %526 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %8, i32 noundef %390) #10
  %527 = trunc i32 %526 to i16
  %528 = bitcast i16 %527 to half
  %529 = fpext half %528 to float
  %530 = or disjoint i32 %30, 22
  %531 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %530) #10
  %532 = trunc i32 %531 to i16
  %533 = bitcast i16 %532 to half
  %534 = fpext half %533 to float
  %535 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %534, float noundef %490) #11
  %536 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %530) #10
  %537 = trunc i32 %536 to i16
  %538 = bitcast i16 %537 to half
  %539 = fpext half %538 to float
  %540 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %539, float noundef %495) #11
  %541 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %530) #10
  %542 = trunc i32 %541 to i16
  %543 = bitcast i16 %542 to half
  %544 = fpext half %543 to float
  %545 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %544, float noundef %500) #11
  %546 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %530) #10
  %547 = trunc i32 %546 to i16
  %548 = bitcast i16 %547 to half
  %549 = fpext half %548 to float
  %550 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %549, float noundef %505) #11
  %551 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %530) #10
  %552 = trunc i32 %551 to i16
  %553 = bitcast i16 %552 to half
  %554 = fpext half %553 to float
  %555 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %554, float noundef %510) #11
  %556 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %530) #10
  %557 = trunc i32 %556 to i16
  %558 = bitcast i16 %557 to half
  %559 = fpext half %558 to float
  %560 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %559, float noundef %515) #11
  %561 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %530) #10
  %562 = trunc i32 %561 to i16
  %563 = bitcast i16 %562 to half
  %564 = fpext half %563 to float
  %565 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %564, float noundef %520) #11
  %566 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %530) #10
  %567 = trunc i32 %566 to i16
  %568 = bitcast i16 %567 to half
  %569 = fpext half %568 to float
  %570 = tail call spir_func float @_Z3fmafff(float noundef %529, float noundef %569, float noundef %525) #11
  %571 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %9, i32 noundef %390) #10
  %572 = trunc i32 %571 to i16
  %573 = bitcast i16 %572 to half
  %574 = fpext half %573 to float
  %575 = or disjoint i32 %30, 24
  %576 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %575) #10
  %577 = trunc i32 %576 to i16
  %578 = bitcast i16 %577 to half
  %579 = fpext half %578 to float
  %580 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %579, float noundef %535) #11
  %581 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %575) #10
  %582 = trunc i32 %581 to i16
  %583 = bitcast i16 %582 to half
  %584 = fpext half %583 to float
  %585 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %584, float noundef %540) #11
  %586 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %575) #10
  %587 = trunc i32 %586 to i16
  %588 = bitcast i16 %587 to half
  %589 = fpext half %588 to float
  %590 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %589, float noundef %545) #11
  %591 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %575) #10
  %592 = trunc i32 %591 to i16
  %593 = bitcast i16 %592 to half
  %594 = fpext half %593 to float
  %595 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %594, float noundef %550) #11
  %596 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %575) #10
  %597 = trunc i32 %596 to i16
  %598 = bitcast i16 %597 to half
  %599 = fpext half %598 to float
  %600 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %599, float noundef %555) #11
  %601 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %575) #10
  %602 = trunc i32 %601 to i16
  %603 = bitcast i16 %602 to half
  %604 = fpext half %603 to float
  %605 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %604, float noundef %560) #11
  %606 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %575) #10
  %607 = trunc i32 %606 to i16
  %608 = bitcast i16 %607 to half
  %609 = fpext half %608 to float
  %610 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %609, float noundef %565) #11
  %611 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %575) #10
  %612 = trunc i32 %611 to i16
  %613 = bitcast i16 %612 to half
  %614 = fpext half %613 to float
  %615 = tail call spir_func float @_Z3fmafff(float noundef %574, float noundef %614, float noundef %570) #11
  %616 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %10, i32 noundef %390) #10
  %617 = trunc i32 %616 to i16
  %618 = bitcast i16 %617 to half
  %619 = fpext half %618 to float
  %620 = or disjoint i32 %30, 26
  %621 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %620) #10
  %622 = trunc i32 %621 to i16
  %623 = bitcast i16 %622 to half
  %624 = fpext half %623 to float
  %625 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %624, float noundef %580) #11
  %626 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %620) #10
  %627 = trunc i32 %626 to i16
  %628 = bitcast i16 %627 to half
  %629 = fpext half %628 to float
  %630 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %629, float noundef %585) #11
  %631 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %620) #10
  %632 = trunc i32 %631 to i16
  %633 = bitcast i16 %632 to half
  %634 = fpext half %633 to float
  %635 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %634, float noundef %590) #11
  %636 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %620) #10
  %637 = trunc i32 %636 to i16
  %638 = bitcast i16 %637 to half
  %639 = fpext half %638 to float
  %640 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %639, float noundef %595) #11
  %641 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %620) #10
  %642 = trunc i32 %641 to i16
  %643 = bitcast i16 %642 to half
  %644 = fpext half %643 to float
  %645 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %644, float noundef %600) #11
  %646 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %620) #10
  %647 = trunc i32 %646 to i16
  %648 = bitcast i16 %647 to half
  %649 = fpext half %648 to float
  %650 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %649, float noundef %605) #11
  %651 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %620) #10
  %652 = trunc i32 %651 to i16
  %653 = bitcast i16 %652 to half
  %654 = fpext half %653 to float
  %655 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %654, float noundef %610) #11
  %656 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %620) #10
  %657 = trunc i32 %656 to i16
  %658 = bitcast i16 %657 to half
  %659 = fpext half %658 to float
  %660 = tail call spir_func float @_Z3fmafff(float noundef %619, float noundef %659, float noundef %615) #11
  %661 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %11, i32 noundef %390) #10
  %662 = trunc i32 %661 to i16
  %663 = bitcast i16 %662 to half
  %664 = fpext half %663 to float
  %665 = or disjoint i32 %30, 28
  %666 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %665) #10
  %667 = trunc i32 %666 to i16
  %668 = bitcast i16 %667 to half
  %669 = fpext half %668 to float
  %670 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %669, float noundef %625) #11
  %671 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %665) #10
  %672 = trunc i32 %671 to i16
  %673 = bitcast i16 %672 to half
  %674 = fpext half %673 to float
  %675 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %674, float noundef %630) #11
  %676 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %665) #10
  %677 = trunc i32 %676 to i16
  %678 = bitcast i16 %677 to half
  %679 = fpext half %678 to float
  %680 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %679, float noundef %635) #11
  %681 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %665) #10
  %682 = trunc i32 %681 to i16
  %683 = bitcast i16 %682 to half
  %684 = fpext half %683 to float
  %685 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %684, float noundef %640) #11
  %686 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %665) #10
  %687 = trunc i32 %686 to i16
  %688 = bitcast i16 %687 to half
  %689 = fpext half %688 to float
  %690 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %689, float noundef %645) #11
  %691 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %665) #10
  %692 = trunc i32 %691 to i16
  %693 = bitcast i16 %692 to half
  %694 = fpext half %693 to float
  %695 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %694, float noundef %650) #11
  %696 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %665) #10
  %697 = trunc i32 %696 to i16
  %698 = bitcast i16 %697 to half
  %699 = fpext half %698 to float
  %700 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %699, float noundef %655) #11
  %701 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %665) #10
  %702 = trunc i32 %701 to i16
  %703 = bitcast i16 %702 to half
  %704 = fpext half %703 to float
  %705 = tail call spir_func float @_Z3fmafff(float noundef %664, float noundef %704, float noundef %660) #11
  %706 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %12, i32 noundef %390) #10
  %707 = trunc i32 %706 to i16
  %708 = bitcast i16 %707 to half
  %709 = fpext half %708 to float
  %710 = or disjoint i32 %30, 30
  %711 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %13, i32 noundef %710) #10
  %712 = trunc i32 %711 to i16
  %713 = bitcast i16 %712 to half
  %714 = fpext half %713 to float
  %715 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %714, float noundef %670) #11
  %716 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %14, i32 noundef %710) #10
  %717 = trunc i32 %716 to i16
  %718 = bitcast i16 %717 to half
  %719 = fpext half %718 to float
  %720 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %719, float noundef %675) #11
  %721 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %15, i32 noundef %710) #10
  %722 = trunc i32 %721 to i16
  %723 = bitcast i16 %722 to half
  %724 = fpext half %723 to float
  %725 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %724, float noundef %680) #11
  %726 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %16, i32 noundef %710) #10
  %727 = trunc i32 %726 to i16
  %728 = bitcast i16 %727 to half
  %729 = fpext half %728 to float
  %730 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %729, float noundef %685) #11
  %731 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %17, i32 noundef %710) #10
  %732 = trunc i32 %731 to i16
  %733 = bitcast i16 %732 to half
  %734 = fpext half %733 to float
  %735 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %734, float noundef %690) #11
  %736 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %18, i32 noundef %710) #10
  %737 = trunc i32 %736 to i16
  %738 = bitcast i16 %737 to half
  %739 = fpext half %738 to float
  %740 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %739, float noundef %695) #11
  %741 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %19, i32 noundef %710) #10
  %742 = trunc i32 %741 to i16
  %743 = bitcast i16 %742 to half
  %744 = fpext half %743 to float
  %745 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %744, float noundef %700) #11
  %746 = tail call spir_func i32 @_Z23intel_sub_group_shuffleij(i32 noundef %20, i32 noundef %710) #10
  %747 = trunc i32 %746 to i16
  %748 = bitcast i16 %747 to half
  %749 = fpext half %748 to float
  %750 = tail call spir_func float @_Z3fmafff(float noundef %709, float noundef %749, float noundef %705) #11
  %751 = insertelement <8 x float> poison, float %715, i64 0
  %752 = insertelement <8 x float> %751, float %720, i64 1
  %753 = insertelement <8 x float> %752, float %725, i64 2
  %754 = insertelement <8 x float> %753, float %730, i64 3
  %755 = insertelement <8 x float> %754, float %735, i64 4
  %756 = insertelement <8 x float> %755, float %740, i64 5
  %757 = insertelement <8 x float> %756, float %745, i64 6
  %758 = insertelement <8 x float> %757, float %750, i64 7
  ret <8 x float> %758
}

; Function Attrs: alwaysinline convergent nounwind
define linkonce_odr spir_func %struct.f32.f32.f32.i8 @__zluda_ptx_impl_div_f32_part1(float %x, float %y) #9 {
  ret %struct.f32.f32.f32.i8 zeroinitializer
}

; Function Attrs: alwaysinline convergent nounwind
define linkonce_odr spir_func float @__zluda_ptx_impl_div_f32_part2(float %x, float %y, float %a, float %b, float %c, i8 %flag) #9 {
  %r = fdiv float %x, %y
  ret float %r
}

; Function Attrs: alwaysinline convergent nounwind
define linkonce_odr spir_func i32 @__zluda_ptx_impl_vote_sync_ballot_b32(i1 %pred, i32 %membermask) #9 {
  %p = zext i1 %pred to i32
  %r = call spir_func i32 @__zlift_vote_ballot(i32 %p)
  ret i32 %r
}

attributes #0 = { alwaysinline convergent norecurse nounwind "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { convergent nounwind "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { convergent mustprogress nofree nounwind willreturn memory(none) "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { alwaysinline convergent mustprogress nofree norecurse nounwind willreturn memory(none) "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #6 = { alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #7 = { convergent norecurse nounwind "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #8 = { convergent mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-builtin-memcpy" "no-builtin-memset" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #9 = { alwaysinline convergent nounwind }
attributes #10 = { convergent nounwind "no-builtin-memcpy" "no-builtin-memset" }
attributes #11 = { convergent nounwind willreturn memory(none) "no-builtin-memcpy" "no-builtin-memset" }
attributes #12 = { convergent nounwind willreturn memory(read) "no-builtin-memcpy" "no-builtin-memset" }

!opencl.ocl.version = !{!0, !0}
!opencl.spir.version = !{!0, !0}
!llvm.ident = !{!1, !1}
!llvm.module.flags = !{!2, !3}

!0 = !{i32 2, i32 0}
!1 = !{!"clang version 20.1.8 (https://github.com/conda-forge/clangdev-feedstock 4bb8e6c8a8e30a94c55be92d093c63f0d8fa92ae)"}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{float 2.500000e+00}
!5 = !{!6, !6, i64 0}
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !11, i64 0}
!10 = !{!"SlifterTmaDesc", !11, i64 0, !6, i64 8, !6, i64 12, !6, i64 16, !6, i64 20, !6, i64 24, !6, i64 28, !6, i64 32, !6, i64 36, !6, i64 40, !6, i64 44, !6, i64 48, !6, i64 52}
!11 = !{!"long", !7, i64 0}
!12 = !{!7, !7, i64 0}
!13 = !{!10, !6, i64 8}
!14 = !{!10, !6, i64 12}
!15 = !{!10, !6, i64 16}
!16 = !{!10, !6, i64 24}
!17 = !{!10, !6, i64 36}
!18 = !{!10, !6, i64 40}
!19 = !{!10, !6, i64 20}
!20 = !{!10, !6, i64 32}
!21 = !{!10, !6, i64 52}
!22 = distinct !{!22, !23, !24}
!23 = !{!"llvm.loop.isvectorized", i32 1}
!24 = !{!"llvm.loop.unroll.runtime.disable"}
!25 = distinct !{!25, !24, !23}
!26 = !{!10, !6, i64 28}
!27 = !{!28, !28, i64 0}
!28 = !{!"short", !7, i64 0}
!29 = !{!30, !30, i64 0}
!30 = !{!"float", !7, i64 0}
!31 = !{float 3.000000e+00}
!32 = !{!33, !33, i64 0}
!33 = !{!"half", !7, i64 0}

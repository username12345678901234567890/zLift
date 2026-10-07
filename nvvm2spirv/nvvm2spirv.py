import argparse 
import os 
import re 
import sys 
TILE_ARG ='__zlift_block_off'
GRID_ARG ='__zlift_grid_x'

def tiling_enabled ():
    return os .environ .get ('ZLIFT_TILE_ARG','1')!='0'
SREG_TO_BUILTIN ={'tid.x':('_Z12get_local_idj',0 ),'tid.y':('_Z12get_local_idj',1 ),'tid.z':('_Z12get_local_idj',2 ),'ctaid.x':('_Z12get_group_idj',0 ),'ctaid.y':('_Z12get_group_idj',1 ),'ctaid.z':('_Z12get_group_idj',2 ),'ntid.x':('_Z14get_local_sizej',0 ),'ntid.y':('_Z14get_local_sizej',1 ),'ntid.z':('_Z14get_local_sizej',2 ),'nctaid.x':('_Z14get_num_groupsj',0 ),'nctaid.y':('_Z14get_num_groupsj',1 ),'nctaid.z':('_Z14get_num_groupsj',2 )}
BUILTIN_ELEM_TY ='i64'
SREG_TO_CONST ={'cluster.ctarank':0 ,'cluster.nctarank':1 ,'clusterid.x':0 ,'clusterid.y':0 ,'clusterid.z':0 ,'nclusterid.x':1 ,'nclusterid.y':1 ,'nclusterid.z':1 ,'cluster.ctaid.x':0 ,'cluster.ctaid.y':0 ,'cluster.ctaid.z':0 ,'cluster.nctaid.x':1 ,'cluster.nctaid.y':1 ,'cluster.nctaid.z':1 ,'warpsize':32 ,'smid':0 ,'nsmid':1 ,'gridid':0 }
WARP_SIZE =32 
SPIR_TRIPLE ='spir64-unknown-unknown'
SPIR_DATALAYOUT ='e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1'
MD_BASE =9000 
MD_OCL_VERSION =MD_BASE 
MD_SUBGROUP_SIZE =MD_BASE +1 
ATTR_PURE ='#0'
ATTR_CONVERGENT ='#1'
ATTR_MEMORY ='#2'
ATTR_GROUPS ={ATTR_PURE :'{ nounwind readnone willreturn }',ATTR_CONVERGENT :'{ convergent nounwind }',ATTR_MEMORY :'{ nounwind }'}

class Emitter :

    def __init__ (self ):
        self .decls ={}
        self .notes ={}

    def need (self ,name ,ret ,params ,spir =True ,attrs =ATTR_PURE ):
        if name not in self .decls :
            cc ='spir_func 'if spir else ''
            self .decls [name ]=f"declare {cc}{ret} @{name}({', '.join(params)}) local_unnamed_addr {attrs}"
        return name 

    def note (self ,text ):
        self .notes [text ]=self .notes .get (text ,0 )+1 
RENAME_LLVM ={'llvm.nvvm.fabs.f':('llvm.fabs.f32','float',['float']),'llvm.nvvm.fabs.ftz.f':('llvm.fabs.f32','float',['float']),'llvm.nvvm.fabs.d':('llvm.fabs.f64','double',['double']),'llvm.nvvm.round.f':('llvm.rint.f32','float',['float']),'llvm.nvvm.round.d':('llvm.rint.f64','double',['double']),'llvm.nvvm.floor.f':('llvm.floor.f32','float',['float']),'llvm.nvvm.floor.d':('llvm.floor.f64','double',['double']),'llvm.nvvm.ceil.f':('llvm.ceil.f32','float',['float']),'llvm.nvvm.ceil.d':('llvm.ceil.f64','double',['double']),'llvm.nvvm.trunc.f':('llvm.trunc.f32','float',['float']),'llvm.nvvm.trunc.d':('llvm.trunc.f64','double',['double']),'llvm.nvvm.brev32':('llvm.bitreverse.i32','i32',['i32']),'llvm.nvvm.brev64':('llvm.bitreverse.i64','i64',['i64']),'llvm.nvvm.sqrt.rn.f':('llvm.sqrt.f32','float',['float']),'llvm.nvvm.sqrt.rn.d':('llvm.sqrt.f64','double',['double']),'llvm.nvvm.fma.rn.f':('llvm.fma.f32','float',['float']*3 ),'llvm.nvvm.fma.rn.d':('llvm.fma.f64','double',['double']*3 )}
FMA_DIRECTED ={'llvm.nvvm.fma.rm.f':('llvm.fma.f32','float'),'llvm.nvvm.fma.rp.f':('llvm.fma.f32','float'),'llvm.nvvm.fma.rz.f':('llvm.fma.f32','float'),'llvm.nvvm.fma.rm.d':('llvm.fma.f64','double'),'llvm.nvvm.fma.rp.d':('llvm.fma.f64','double'),'llvm.nvvm.fma.rz.d':('llvm.fma.f64','double')}
APPROX_TO_NATIVE ={'rcp':('_Z12native_recipf','float',['float']),'rsqrt':('_Z12native_rsqrtf','float',['float']),'ex2':('_Z11native_exp2f','float',['float']),'lg2':('_Z11native_log2f','float',['float']),'sin':('_Z10native_sinf','float',['float']),'cos':('_Z10native_cosf','float',['float']),'sqrt':('_Z11native_sqrtf','float',['float']),'tanh':('_Z10native_tanf','float',['float'])}
APPROX_RE =re .compile ('^llvm\\.nvvm\\.(\\w+)\\.approx(?:\\.ftz)?\\.f$')
MEM_FENCE_ALL =3 
REDUX_TO_BUILTIN ={'add':'_Z20sub_group_reduce_addi','min':'_Z20sub_group_reduce_mini','max':'_Z20sub_group_reduce_maxi','umin':'_Z20sub_group_reduce_minj','umax':'_Z20sub_group_reduce_maxj','and':'_Z20sub_group_reduce_andi','or':'_Z20sub_group_reduce_ori','xor':'_Z20sub_group_reduce_xori'}
SHUFFLE ={'down':('_Z28intel_sub_group_shuffle_down',3 ),'up':('_Z26intel_sub_group_shuffle_up',3 ),'bfly':('_Z27intel_sub_group_shuffle_xor',2 ),'idx':('_Z23intel_sub_group_shuffle',2 )}
SHFL_RE =re .compile ('^llvm\\.nvvm\\.shfl\\.sync\\.(down|up|bfly|idx)\\.(f32|i32)$')
MMA_SHAPES ={'m16n8k8.row.col.f32.f32':('__zlift_mma_m16n8k8_f32_f16',2 ,1 ,'i32','float',4 ),'m16n8k16.row.col.f32.f32':('__zlift_mma_m16n8k16_f32_f16',4 ,2 ,'i32','float',4 ),'m16n8k8.row.col.bf16':('__zlift_mma_m16n8k8_f32_bf16',2 ,1 ,'i32','float',4 ),'m16n8k16.row.col.bf16':('__zlift_mma_m16n8k16_f32_bf16',4 ,2 ,'i32','float',4 ),'m16n8k8.row.col.f16.f16':('__zlift_mma_m16n8k8_f16_f16',2 ,1 ,'i32','i32',2 ),'m16n8k16.row.col.f16.f16':('__zlift_mma_m16n8k16_f16_f16',4 ,2 ,'i32','i32',2 ),'m16n8k8.row.col.tf32':('__zlift_mma_m16n8k8_f32_tf32',4 ,2 ,'i32','float',4 ),'m8n8k4.row.col.f64':('__zlift_mma_m8n8k4_f64',1 ,1 ,'double','double',2 ),'m16n8k16.row.col.f64':('__zlift_mma_m16n8k16_f64',8 ,4 ,'double','double',4 ),'m8n8k16.row.col.satfinite.s8':('__zlift_mma_m8n8k16_s32_s8',1 ,1 ,'i32','i32',2 ),'m16n8k32.row.col.satfinite.s8':('__zlift_mma_m16n8k32_s32_s8',4 ,2 ,'i32','i32',4 )}
MMA_RE =re .compile ('^llvm\\.nvvm\\.mma\\.(.+)$')
SPIRV_EXTS =['SPV_INTEL_subgroups','SPV_KHR_bit_instructions','SPV_KHR_expect_assume','SPV_KHR_no_integer_wrap_decoration','SPV_EXT_shader_atomic_float_add']
SPIRV_EXT_MATRIX ='SPV_INTEL_subgroup_matrix_multiply_accumulate'

def llc_knows_matrix_extension (llc :str )->bool :
    import subprocess 
    try :
        r =subprocess .run ([llc ,'-mtriple=spirv64-unknown-unknown',f'--spirv-ext=+{SPIRV_EXT_MATRIX}','-o',os .devnull ,os .devnull ],capture_output =True ,text =True ,timeout =30 )
    except Exception :
        return False 
    return 'Unknown SPIR-V extension'not in (r .stderr or '')
_XMX =None 

def xmx_enabled ()->bool :
    global _XMX 
    v =os .environ .get ('ZLIFT_XMX')
    if v is not None :
        return v =='1'
    if _XMX is None :
        import glob as _glob 
        root =os .path .dirname (os .path .dirname (os .path .abspath (__file__ )))
        found =sorted (_glob .glob (os .path .join (root ,'ZLUDA/target/release/build/llvm_zluda-*/out/build/bin/llc')))
        _XMX =bool (found )and llc_knows_matrix_extension (found [-1 ])
    return _XMX 

def spirv_exts_for (llc :str ):
    exts =list (SPIRV_EXTS )
    if llc and llc_knows_matrix_extension (llc ):
        exts .append (SPIRV_EXT_MATRIX )
    return exts 
SHFL_TY ={'f32':'float','i32':'i32'}
CONST_BANK_STRIDE =4096 
SLIFTER_ARG_BASE =528 

def split_type_val (arg :str ):
    arg =arg .strip ()
    if arg [0 ]in '[{<':
        close ={'[':']','{':'}','<':'>'}[arg [0 ]]
        depth ,i =(0 ,0 )
        for i ,ch in enumerate (arg ):
            if ch ==arg [0 ]:
                depth +=1 
            elif ch ==close :
                depth -=1 
                if depth ==0 :
                    break 
        i +=1 
        m =re .match ('\\s*(?:addrspace\\(\\d+\\)\\s*)?\\*+',arg [i :])
        if m :
            i +=m .end ()
        while i <len (arg )and arg [i ]in ' *':
            i +=1 
        return (arg [:i ].strip (),arg [i :].strip ())
    parts =arg .split (None ,1 )
    return (parts [0 ],parts [1 ])if len (parts )==2 else (parts [0 ],'')

def split_args (s :str ):
    out ,depth ,cur =([],0 ,'')
    for ch in s :
        if ch in '([{<':
            depth +=1 
        elif ch in ')]}>':
            depth -=1 
        if ch ==','and depth ==0 :
            out .append (cur .strip ())
            cur =''
        else :
            cur +=ch 
    if cur .strip ():
        out .append (cur .strip ())
    return [split_type_val (a )for a in out ]

def derive (lhs :str ,suffix :str )->str :
    if lhs .startswith ('%"')and lhs .endswith ('"'):
        return f'%"{lhs[2:-1]}{suffix}"'
    if lhs [1 :].isdigit ():
        return f'%v{lhs[1:]}{suffix}'
    return f'{lhs}{suffix}'

def lower_intrinsic (lhs ,ret ,name ,args ,em :Emitter ):
    if name in RENAME_LLVM :
        new ,rty ,ptys =RENAME_LLVM [name ]
        em .need (new ,rty ,ptys ,spir =False )
        argstr =', '.join ((f'{t} {v}'for t ,v in args ))
        return f'{lhs} = call {rty} @{new}({argstr})'
    if name in FMA_DIRECTED :
        new ,rty =FMA_DIRECTED [name ]
        em .need (new ,rty ,[rty ]*3 ,spir =False )
        em .note (f'{name}: directed rounding lowered to round-to-nearest')
        argstr =', '.join ((f'{t} {v}'for t ,v in args ))
        return f'{lhs} = call {rty} @{new}({argstr})'
    m =APPROX_RE .match (name )
    if m and m .group (1 )in APPROX_TO_NATIVE :
        new ,rty ,ptys =APPROX_TO_NATIVE [m .group (1 )]
        em .need (new ,rty ,ptys )
        em .note (f"{name}: lowered to OpenCL {new.split('native_')[-1]} (accuracy is implementation-defined on both sides)")
        argstr =', '.join ((f'{t} {v}'for t ,v in args ))
        return f'{lhs} = call spir_func {rty} @{new}({argstr})'
    if name in ('llvm.nvvm.barrier0','llvm.nvvm.barrier.sync','llvm.nvvm.barrier.sync.cnt','llvm.nvvm.bar.sync'):
        em .need ('_Z7barrierj','void',['i32'],attrs =ATTR_CONVERGENT )
        return f'call spir_func void @_Z7barrierj(i32 {MEM_FENCE_ALL})'
    m =re .match ('^llvm\\.nvvm\\.barrier0\\.(or|and|popc)$',name )
    if m :
        kind =m .group (1 )
        fn ={'or':'_Z14work_group_anyi','and':'_Z14work_group_alli','popc':'_Z21work_group_reduce_addi'}[kind ]
        em .need (fn ,'i32',['i32'],attrs =ATTR_CONVERGENT )
        pred_ty ,pred =args [-1 ]
        wide =derive (lhs ,'.w')
        pre =f'{wide} = zext {pred_ty} {pred} to i32\n  'if pred_ty !='i32'else ''
        arg =pred if pred_ty =='i32'else wide 
        if kind =='popc':
            nz =derive (lhs ,'.nz')
            one =derive (lhs ,'.b')
            pre +=f'{nz} = icmp ne i32 {arg}, 0\n  {one} = zext i1 {nz} to i32\n  '
            arg =one 
        tail =''
        dst =lhs 
        if ret =='i1':
            got =derive (lhs ,'.v')
            tail =f'\n  {lhs} = icmp ne i32 {got}, 0'
            dst =got 
        em .note (f"barrier0.{kind}: lowered to {fn.split('_Z')[-1][2:]}, which barriers and reduces in one call")
        return f'{pre}{dst} = call spir_func i32 @{fn}(i32 {arg})'+tail 
    if name in ('llvm.nvvm.bar.warp.sync','llvm.nvvm.barrier.warp.sync'):
        em .need ('_Z17sub_group_barrierj','void',['i32'],attrs =ATTR_CONVERGENT )
        em .note ('bar.warp.sync: mask operand dropped, lowered to a full sub-group barrier')
        return f'call spir_func void @_Z17sub_group_barrierj(i32 {MEM_FENCE_ALL})'
    if name .startswith ('llvm.nvvm.membar.'):
        fn ='_Z22atomic_work_item_fencej12memory_order12memory_scope'
        em .need (fn ,'void',['i32','i32','i32'],attrs =ATTR_CONVERGENT )
        return f'call spir_func void @{fn}(i32 3, i32 5, i32 2)'
    if name in ('llvm.nvvm.vote.all.sync','llvm.nvvm.vote.any.sync'):
        kind ='all'if '.all.'in name else 'any'
        fn =f'_Z13sub_group_{kind}i'
        em .need (fn ,'i32',['i32'],attrs =ATTR_CONVERGENT )
        em .note (f'vote.{kind}.sync: membermask operand dropped')
        pred_ty ,pred =args [-1 ]
        wide =derive (lhs ,'.w')
        got =derive (lhs ,'.v')
        pre =f'{wide} = zext {pred_ty} {pred} to i32\n  'if pred_ty !='i32'else ''
        arg =pred if pred_ty =='i32'else wide 
        tail =f'\n  {lhs} = icmp ne i32 {got}, 0'if ret =='i1'else ''
        dst =got if ret =='i1'else lhs 
        return f'{pre}{dst} = call spir_func i32 @{fn}(i32 {arg})'+tail 
    m =re .match ('^llvm\\.nvvm\\.(fmax|fmin)(?:\\.ftz)?\\.f16x2$',name )
    if m :
        new =f"llvm.{('maxnum' if m.group(1) == 'fmax' else 'minnum')}.v2f16"
        em .need (new ,'<2 x half>',['<2 x half>']*2 ,spir =False )
        argstr =', '.join ((f'{t} {v}'for t ,v in args ))
        return f'{lhs} = call <2 x half> @{new}({argstr})'
    if name in ('llvm.nvvm.match.any.sync.i32','llvm.nvvm.match.any.sync.b32'):
        em .need ('__zlift_match_any_b32','i32',['i32'],attrs =ATTR_CONVERGENT )
        em .note ('match.any.sync: membermask operand dropped')
        val =args [-1 ]
        return f'{lhs} = call spir_func i32 @__zlift_match_any_b32({val[0]} {val[1]})'
    if name =='llvm.nvvm.activemask':
        em .need ('_Z22get_sub_group_local_idv','i32',[],attrs =ATTR_CONVERGENT )
        em .need ('_Z20sub_group_reduce_addi','i32',['i32'],attrs =ATTR_CONVERGENT )
        lid =derive (lhs ,'.lid')
        bit =derive (lhs ,'.bit')
        return f'{lid} = call spir_func i32 @_Z22get_sub_group_local_idv()\n  {bit} = shl i32 1, {lid}\n  {lhs} = call spir_func i32 @_Z20sub_group_reduce_addi(i32 {bit})'
    if name =='llvm.nvvm.read.ptx.sreg.laneid':
        em .need ('_Z22get_sub_group_local_idv','i32',[],attrs =ATTR_CONVERGENT )
        return f'{lhs} = call spir_func i32 @_Z22get_sub_group_local_idv()'
    if name .startswith ('llvm.nvvm.read.ptx.sreg.lanemask.'):
        which =name .rsplit ('.',1 )[1 ]
        em .need ('_Z22get_sub_group_local_idv','i32',[],attrs =ATTR_CONVERGENT )
        lid =derive (lhs ,'.lid')
        head =f'{lid} = call spir_func i32 @_Z22get_sub_group_local_idv()'
        one =derive (lhs ,'.m')
        if which =='eq':
            return f'{head}\n  {lhs} = shl i32 1, {lid}'
        if which =='lt':
            return f'{head}\n  {one} = shl i32 1, {lid}\n  {lhs} = sub i32 {one}, 1'
        if which =='le':
            return f'{head}\n  {one} = shl i32 2, {lid}\n  {lhs} = sub i32 {one}, 1'
        if which =='gt':
            sub =derive (lhs ,'.s')
            return f'{head}\n  {one} = shl i32 2, {lid}\n  {sub} = sub i32 {one}, 1\n  {lhs} = xor i32 {sub}, -1'
        if which =='ge':
            sub =derive (lhs ,'.s')
            return f'{head}\n  {one} = shl i32 1, {lid}\n  {sub} = sub i32 {one}, 1\n  {lhs} = xor i32 {sub}, -1'
    if name .startswith ('llvm.nvvm.redux.sync.'):
        op =name [len ('llvm.nvvm.redux.sync.'):]
        if op in REDUX_TO_BUILTIN :
            b =REDUX_TO_BUILTIN [op ]
            em .need (b ,'i32',['i32'],attrs =ATTR_CONVERGENT )
            em .note (f'redux.sync.{op}: membermask operand dropped')
            return f'{lhs} = call spir_func i32 @{b}({args[0][0]} {args[0][1]})'
    if name in ('llvm.nvvm.vote.ballot.sync','llvm.nvvm.vote.ballot'):
        pred_ty ,pred =args [-1 ]
        em .need ('_Z22get_sub_group_local_idv','i32',[],attrs =ATTR_CONVERGENT )
        em .need ('_Z20sub_group_reduce_addi','i32',['i32'],attrs =ATTR_CONVERGENT )
        lid =derive (lhs ,'.lid')
        bit =derive (lhs ,'.bit')
        sel =derive (lhs ,'.sel')
        pred_i1 =pred if pred_ty =='i1'else derive (lhs ,'.p')
        pre =''
        if pred_ty !='i1':
            pre =f'{pred_i1} = icmp ne {pred_ty} {pred}, 0\n  '
        return f'{pre}{lid} = call spir_func i32 @_Z22get_sub_group_local_idv()\n  {bit} = shl i32 1, {lid}\n  {sel} = select i1 {pred_i1}, i32 {bit}, i32 0\n  {lhs} = call spir_func i32 @_Z20sub_group_reduce_addi(i32 {sel})'
    m =MMA_RE .match (name )
    if m and m .group (1 )in MMA_SHAPES :
        return lower_mma (lhs ,ret ,m .group (1 ),args ,em )
    m =SHFL_RE .match (name )
    if m :
        return lower_shuffle (lhs ,m .group (1 ),m .group (2 ),args ,em )
    return None 

def lower_mma (lhs ,ret ,shape ,args ,em :Emitter ):
    fn ,na ,nb ,fty ,aty ,nc =MMA_SHAPES [shape ]
    em .need (fn ,f'<{nc} x {aty}>',[fty ]*(na +nb )+[f'<{nc} x {aty}>'],attrs =ATTR_CONVERGENT )
    em .note (f"mma.{shape.split('.')[0]} emulated with sub-group shuffles (no XMX)")
    lines ,regs =([],[])
    for i in range (na +nb ):
        ty ,val =args [i ]
        if ty ==fty :
            regs .append (val )
            continue 
        nm =derive (lhs ,f'.r{i}')
        lines .append (f'{nm} = bitcast {ty} {val} to {fty}')
        regs .append (nm )
    cur ='undef'
    for i in range (nc ):
        ty ,val =args [na +nb +i ]
        if ty !=aty :
            nm =derive (lhs ,f'.a{i}')
            lines .append (f'{nm} = bitcast {ty} {val} to {aty}')
            val =nm 
        nxt =derive (lhs ,f'.c{i}')
        lines .append (f'{nxt} = insertelement <{nc} x {aty}> {cur}, {aty} {val}, i32 {i}')
        cur =nxt 
    res =derive (lhs ,'.mma')
    lines .append (f'{res} = call spir_func <{nc} x {aty}> @{fn}('+', '.join ((f'{fty} {r}'for r in regs ))+f', <{nc} x {aty}> {cur})')
    field =ret .strip ('{} ').split (',')[0 ].strip ()
    agg ='undef'
    for i in range (nc ):
        el =derive (lhs ,f'.e{i}')
        lines .append (f'{el} = extractelement <{nc} x {aty}> {res}, i32 {i}')
        if field !=aty :
            back =derive (lhs ,f'.f{i}')
            lines .append (f'{back} = bitcast {aty} {el} to {field}')
            el =back 
        nxt =lhs if i ==nc -1 else derive (lhs ,f'.s{i}')
        lines .append (f'{nxt} = insertvalue {ret} {agg}, {field} {el}, {i}')
        agg =nxt 
    return '\n  '.join (lines )

def lower_shuffle (lhs ,mode ,ety ,args ,em :Emitter ):
    base ,nargs =SHUFFLE [mode ]
    carrier ='i32'if ety =='f32'else SHFL_TY [ety ]
    ty =carrier 
    if nargs ==3 :
        fn =base +'ii'+'j'
        params =[ty ,ty ,'i32']
    else :
        fn =base +'i'+'j'
        params =[ty ,'i32']
    em .need (fn ,ty ,params ,attrs =ATTR_CONVERGENT )
    val =args [1 ][1 ]
    delta =args [2 ][1 ]
    shuf =derive (lhs ,'.sh')
    pre ,post =('','')
    out =lhs 
    if ety =='f32':
        vin =derive (lhs ,'.vi')
        pre =f'{vin} = bitcast float {val} to i32\n  '
        val =vin 
        out =derive (lhs ,'.ri')
        post =f'\n  {lhs} = bitcast i32 {out} to float'
    if nargs ==3 :
        call =f'{shuf} = call spir_func {ty} @{fn}({ty} {val}, {ty} {val}, i32 {delta})'
    else :
        call =f'{shuf} = call spir_func {ty} @{fn}({ty} {val}, i32 {delta})'
    if mode not in ('down','up'):
        return pre +call .replace (shuf ,out ,1 )+post 
    em .need ('_Z22get_sub_group_local_idv','i32',[],attrs =ATTR_CONVERGENT )
    lid =derive (lhs ,'.lid')
    idx =derive (lhs ,'.idx')
    inb =derive (lhs ,'.inb')
    if mode =='down':
        idx_expr =f'{idx} = add i32 {lid}, {delta}'
        cmp =f'{inb} = icmp ult i32 {idx}, {WARP_SIZE}'
    else :
        idx_expr =f'{idx} = add i32 {lid}, 0'
        cmp =f'{inb} = icmp uge i32 {lid}, {delta}'
    return pre +f'{lid} = call spir_func i32 @_Z22get_sub_group_local_idv()\n  {idx_expr}\n  {cmp}\n  {call}\n  {out} = select i1 {inb}, {ty} {shuf}, {ty} {val}'+post 

def parse_kernels (ir :str )->set :
    kernels =set ()
    for m in re .finditer ('^!\\d+\\s*=\\s*!\\{[^}]*@"?([A-Za-z0-9_$.]+)"?[^}]*!"kernel"[^}]*\\}',ir ,re .M ):
        kernels .add (m .group (1 ))
    return kernels 

def rewrite_header (ir :str )->str :
    ir =re .sub ('^target triple\\s*=\\s*".*"$',f'target triple = "{SPIR_TRIPLE}"',ir ,flags =re .M )
    ir =re .sub ('^target datalayout\\s*=\\s*".*"$',f'target datalayout = "{SPIR_DATALAYOUT}"',ir ,flags =re .M )
    return ir 

def rewrite_module_globals (ir :str )->str :

    def fix (m ):
        name ,rest =(m .group (1 ),m .group (2 ))
        if 'addrspace('in rest .split ('=')[0 ]:
            return m .group (0 )
        space =1 
        rest2 =re .sub ('\\b(global|constant)\\b',f'addrspace({space}) \\1',rest ,count =1 )
        return f'@"{name}" ={rest2}'
    return re .sub ('^@"?([A-Za-z0-9_$.]+)"?\\s*=([^\\n]*\\b(?:global|constant)\\b[^\\n]*)$',fix ,ir ,flags =re .M )
SLM_LIMIT =int (os .environ .get ('ZLIFT_SLM_LIMIT',128 *1024 ))
XMX_SCRATCH_BYTES =8 *1024 
SHM_GUARD_BYTES =64 

def guard_relocated_shared (ir :str ,moved ,em :Emitter )->str :
    if not moved or os .environ .get ('ZLIFT_SHM_GUARD')=='0':
        return ir 
    sizes =dict (moved )
    lines =ir .split ('\n')
    out ,n ,guarded =([],0 ,0 )
    pat =re .compile ('^(\\s*)('+VAL +') = getelementptr(?: inbounds)? \\[\\d+ x i8\\], \\[\\d+ x i8\\] addrspace\\(1\\)\\* @"([A-Za-z0-9_$.]+)", i32 0, i32 (\\S+)$')
    for line in lines :
        m =pat .match (line )
        if not m or m .group (3 )not in sizes :
            out .append (line )
            continue 
        ind ,dst ,name ,idx =m .groups ()
        size =sizes [name ]
        total =size +SHM_GUARD_BYTES 
        g =f'%"shmg{n}'
        n +=1 
        guarded +=1 
        out +=[f'{ind}{g}_ok" = icmp ult i32 {idx}, {size}',f'{ind}{g}_idx" = select i1 {g}_ok", i32 {idx}, i32 {size}',f'{ind}{dst} = getelementptr inbounds [{total} x i8], [{total} x i8] addrspace(1)* @"{name}", i32 0, i32 {g}_idx"']
    if not guarded :
        return ir 
    em .note (f'workgroup memory backed by global memory is bounds-checked ({guarded} accesses); an out-of-range one is sent to a guard region instead of running off the end')
    text ='\n'.join (out )
    for name ,size in moved :
        total =size +SHM_GUARD_BYTES 
        text =re .sub (f'^@"{re.escape(name)}" = internal addrspace\\(1\\) global \\[{size} x i8\\][^\\n]*$',f'@"{name}" = addrspace(1) global [{total} x i8] zeroinitializer, align 16',text ,flags =re .M )
    return text 

def define_shared_memory (ir :str ,em :Emitter ,shared_bytes :int )->str :
    moved =[]
    scratch =XMX_SCRATCH_BYTES if xmx_enabled ()and 'wgmma.mma_async'in ir else 0 

    def fix (m ):
        name ,declared =(m .group (1 ),int (m .group (2 )))
        size =max (declared ,shared_bytes )
        if scratch :
            size =(size +15 )//16 *16 +scratch 
        if size >SLM_LIMIT :
            em .note (f"@{name}: {size} bytes of workgroup memory is past this device's {SLM_LIMIT}, so it is backed by global memory (slower, and it runs)")
            moved .append ((name ,size ))
            return f'@"{name}" = internal addrspace(1) global [{size} x i8] zeroinitializer, align 16'
        em .note (f'@{name}: external workgroup memory defined, {declared} -> {size} bytes (room for dynamic shared)')
        return f'@"{name}" = internal addrspace(3) global [{size} x i8] zeroinitializer, align 16'
    out =re .sub ('^@"?([A-Za-z0-9_$.]+)"?\\s*=\\s*external addrspace\\(3\\) global \\[(\\d+) x i8\\][^\\n]*$',fix ,ir ,flags =re .M )
    if not moved :
        return out 
    for name ,_size in moved :
        out =out .replace (f'addrspace(3)* @"{name}"',f'addrspace(1)* @"{name}"')
        tainted =set (re .findall (f'^\\s*({VAL}) = getelementptr[^\\n]*addrspace\\(1\\)\\* @"{re.escape(name)}"',out ,re .M ))
        for _ in range (8 ):
            lines ,grew =(out .split ('\n'),False )
            for i ,line in enumerate (lines ):
                if 'addrspace(3)'not in line :
                    continue 
                if not any ((t in line for t in tainted )):
                    continue 
                lines [i ]=line .replace ('addrspace(3)','addrspace(1)')
                m2 =re .match (f'^\\s*({VAL}) = ',lines [i ])
                if m2 and m2 .group (1 )not in tainted :
                    tainted .add (m2 .group (1 ))
                grew =True 
            out ='\n'.join (lines )
            if not grew :
                break 
    return guard_relocated_shared (out ,moved ,em )

def rewrite_sregs (ir :str ,em :Emitter )->str :

    def repl (m ):
        lhs ,sreg =(m .group (1 ),m .group (2 ))
        if sreg in SREG_TO_CONST :
            em .note (f'%{sreg}: Xe has no equivalent, folded to {SREG_TO_CONST[sreg]}')
            return f'{lhs} = add i32 0, {SREG_TO_CONST[sreg]}'
        if sreg not in SREG_TO_BUILTIN :
            return m .group (0 )
        builtin ,dim =SREG_TO_BUILTIN [sreg ]
        em .need (builtin ,BUILTIN_ELEM_TY ,['i32'])
        tmp =derive (lhs ,'.bi')
        body =f'{tmp} = call spir_func {BUILTIN_ELEM_TY} @{builtin}(i32 {dim})'
        if sreg =='nctaid.x'and tiling_enabled ()and (os .environ .get ('ZLIFT_NO_GRID_ARG')!='1'):
            return f'{lhs} = add i32 0, %"{GRID_ARG}"'
        if sreg =='ctaid.x'and tiling_enabled ():
            raw =derive (lhs ,'.raw')
            return f'{body}\n  {raw} = trunc {BUILTIN_ELEM_TY} {tmp} to i32\n  {lhs} = add i32 {raw}, %"{TILE_ARG}"'
        return f'{body}\n  {lhs} = trunc {BUILTIN_ELEM_TY} {tmp} to i32'
    ir =re .sub ('(%"?[A-Za-z0-9_$.:]+"?)\\s*=\\s*call i32 @"?llvm\\.nvvm\\.read\\.ptx\\.sreg\\.([a-z0-9.]+)"?\\(\\)',repl ,ir )
    return ir 

def rewrite_intrinsics (ir :str ,em :Emitter )->str :
    call_re =re .compile ('^(\\s*)(?:(%"?[A-Za-z0-9_$.:]+"?)\\s*=\\s*)?call\\s+(?:spir_func\\s+)?([A-Za-z0-9_<>\\[\\]{}*, ]+?)\\s+@"?(llvm\\.nvvm\\.[A-Za-z0-9_.]+)"?\\((.*)\\)\\s*$',re .M )

    def repl (m ):
        indent ,lhs ,ret ,name ,argstr =m .groups ()
        out =lower_intrinsic (lhs ,ret .strip (),name ,split_args (argstr ),em )
        return m .group (0 )if out is None else indent +out 
    return call_re .sub (repl ,ir )

def drop_dead_declares (ir :str )->str :
    lines =ir .split ('\n')
    uses ={}
    for line in lines :
        if line .startswith ('declare '):
            continue 
        for name in re .findall ('@"?(llvm\\.nvvm\\.[A-Za-z0-9_.]+)"?\\(',line ):
            uses [name ]=uses .get (name ,0 )+1 
    out =[]
    for line in lines :
        m =re .match ('^declare .*@"?(llvm\\.nvvm\\.[A-Za-z0-9_.]+)"?\\(',line )
        if m and (not uses .get (m .group (1 ))):
            continue 
        out .append (line )
    return '\n'.join (out )

def drop_unresolvable_calls (ir :str ,em :Emitter )->str :
    defined =set (re .findall ('^define [^@]*@"?([A-Za-z_$][\\w.$]*)"?\\(',ir ,re .M ))
    keep =('llvm.','_Z','__spirv','__zlift','intel_','__builtin')
    dropped =set ()
    for m in re .finditer ('^declare [^@]*@"?([A-Za-z_$][\\w.$]*)"?\\(\\s*\\)',ir ,re .M ):
        name =m .group (1 )
        if name in defined or name .startswith (keep ):
            continue 
        if not re .search (f'^declare void @"?{re.escape(name)}"?\\(\\s*\\)',ir ,re .M ):
            continue 
        dropped .add (name )
    for name in sorted (dropped ):
        em .note (f'@{name} is called and never defined — a CUDA-runtime ABI call with no device body — so the call is dropped rather than left to fail the module build')
        ir =re .sub (f'^\\s*call void @"?{re.escape(name)}"?\\(\\s*\\)\\s*$\\n','',ir ,flags =re .M )
        ir =re .sub (f'^declare void @"?{re.escape(name)}"?\\(\\s*\\)\\s*$\\n','',ir ,flags =re .M )
    return ir 

def rewrite_kernel_defs (ir :str ,kernels :set ,em :Emitter )->str :
    for k in kernels :
        ir =re .sub (f'^define (?!spir_kernel\\b)((?:\\w+ )*)void @"?{re.escape(k)}"?\\(',f'define spir_kernel void @"{k}"(',ir ,flags =re .M )
    ir =re .sub ('^(define spir_kernel void @[^\\n]*?\\))\\s*$',f'\\1 !intel_reqd_sub_group_size !{MD_SUBGROUP_SIZE}',ir ,flags =re .M )
    return ir 
_WARP_OP =re .compile ('@(?:_Z\\d+sub_group\\w*|_Z\\d+intel_sub_group\\w*|__spirv_(?:Group|Subgroup)\\w*|zlift_shfl\\w*|zlift_frag\\w*|zlift_pick4|__zlift_activemask|__zlift_elect\\w*|__zlift_vote\\w*|__zlift_match\\w*|__zlift_wgmma\\w*|__zlift_mma\\w*|zlift_laneid|zlift_warpid)')

def _uses_warp_op (ir :str )->bool :
    return _WARP_OP .search (ir )is not None 
PTR_PROPAGATING =('getelementptr','bitcast','addrspacecast','select','phi')

def _with_space (line :str ,space :int )->str :
    line =re .sub ('(addrspace\\(\\d+\\))?\\s*\\*',lambda m :m .group (0 )if m .group (1 )else f' addrspace({space})*',line )
    return re .sub ('(?<![\\w."])ptr(?!\\s+addrspace)(?=\\s+[%@])',f'ptr addrspace({space})',line )

def _first_operand_comma (line :str ):
    depth =0 
    for i ,c in enumerate (line ):
        if c in '<[{(':
            depth +=1 
        elif c in '>]})':
            depth -=1 
        elif c ==','and depth ==0 :
            return i 
    return None 

def retype_pointer_chain (ir :str ,roots :set ,space :int =1 )->str :
    lines =ir .split ('\n')
    tainted =set ()
    for i ,line in enumerate (lines ):
        if line .startswith ('define '):
            tainted =set ()
            continue 
        defn =re .match ('\\s*(%"[^"]+")\\s*=\\s*([a-z]+)',line )
        if defn :
            name ,op =defn .groups ()
            rhs =line [line .index ('=')+1 :]
            if name in roots and f'addrspace({space})'in rhs :
                tainted .add (name )
                continue 
            if name in tainted :
                continue 
            if not set (re .findall ('%"[^"]+"',line [line .index ('=')+1 :]))&tainted :
                continue 
            if op in PTR_PROPAGATING :
                lines [i ]=_with_space (line ,space )
                tainted .add (name )
            elif op in ('load','ptrtoint'):
                lines [i ]=_with_space (line ,space )
        elif line .lstrip ().startswith ('store'):
            cut =_first_operand_comma (line )
            if cut is not None :
                head ,dest =(line [:cut ],line [cut +1 :])
                if set (re .findall ('%"[^"]+"',dest ))&tainted :
                    lines [i ]=head +','+_with_space (dest ,space )
    return '\n'.join (lines )

def global_to_argument (ir :str ,em :Emitter ,symbol :str ,note :str ):
    m =re .search (f'^@"?{re.escape(symbol)}"?\\s*=[^\\n]*?\\[(\\d+) x (?:\\[(\\d+) x )?i8\\]',ir ,re .M )
    if not m :
        return (ir ,None )
    outer =int (m .group (1 ))
    inner =int (m .group (2 ))if m .group (2 )else None 
    quoted =f'@"{symbol}"'
    uses =sum ((1 for line in ir .split ('\n')if quoted in line and (not line .startswith ('@'))))
    if not uses :
        return (re .sub (f'^@"?{re.escape(symbol)}"?\\s*=[^\\n]*$','',ir ,flags =re .M ),None )
    if inner is not None and inner <CONST_BANK_STRIDE :
        old_ty =f'[{outer} x [{inner} x i8]]'
        new_ty =f'[{outer} x [{CONST_BANK_STRIDE} x i8]]'
        ir ='\n'.join ((l .replace (old_ty ,new_ty )if quoted in l else l for l in ir .split ('\n')))
        inner =CONST_BANK_STRIDE 
    base_ty =f'[{outer} x [{inner} x i8]]'if inner else f'[{outer} x i8]'
    ty =f'{base_ty} addrspace(1)*'
    ir =re .sub (f'^@"?{re.escape(symbol)}"?\\s*=[^\\n]*$','',ir ,flags =re .M )
    param =f'%"{symbol}_arg"'

    def add_param (dm ):
        head ,params ,tail =dm .groups ()
        sep =', 'if params .strip ()else ''
        return f'{head}({params}{sep}{ty} {param}){tail}'
    ir =re .sub ('^(define spir_kernel void @"[A-Za-z0-9_$.]+")\\((.*)\\)([^\\n]*)$',add_param ,ir ,flags =re .M )
    roots ={m .group (1 )for m in re .finditer (f'^\\s*(%"[^"]+")\\s*=[^\\n]*{re.escape(quoted)}',ir ,re .M )}
    ir =re .sub (f'{re.escape(base_ty)}(?:\\s+addrspace\\(\\d+\\))?\\s*\\*(\\s*){re.escape(quoted)}',lambda um :f'{ty}{um.group(1)}{param}',ir )
    ir =ir .replace (quoted ,param )
    ir =retype_pointer_chain (ir ,roots )
    em .note (note )
    return (ir ,{'banks':outer ,'stride':inner }if inner else {'size':outer })

def const_mem_to_argument (ir :str ,em :Emitter ):
    return global_to_argument (ir ,em ,'const_mem','const_mem moved from a module global to a kernel argument (a host cannot write a SPIR-V module global)')

def nv_global_to_argument (ir :str ,em :Emitter ):
    return global_to_argument (ir ,em ,'__slifter_nv_global','__slifter_nv_global moved to a kernel argument so the host can fill the .nv.global section')
NV_GLOBAL_INIT_INLINE_MAX =64 *1024 

def _llvm_cstring_bytes (text :str )->bytes :
    out =bytearray ()
    i =0 
    while i <len (text ):
        ch =text [i ]
        if ch =='\\'and i +2 <len (text ):
            nxt =text [i +1 :i +3 ]
            if nxt =='\\\\':
                out .append (92 )
                i +=2 
                continue 
            try :
                out .append (int (nxt ,16 ))
                i +=3 
                continue 
            except ValueError :
                pass 
        out .append (ord (ch )&255 )
        i +=1 
    return bytes (out )

def nv_global_init_to_argument (ir :str ,em :Emitter ):
    m =re .search ('^@"?__slifter_nv_global_init"?\\s*=[^\\n]*?\\[(\\d+) x i8\\]\\s*c"((?:[^"\\\\]|\\\\.)*)"',ir ,re .M )
    if not m or int (m .group (1 ))<=NV_GLOBAL_INIT_INLINE_MAX :
        return (ir ,None ,b'')
    data =_llvm_cstring_bytes (m .group (2 ))
    ir ,layout =global_to_argument (ir ,em ,'__slifter_nv_global_init','__slifter_nv_global_init moved to a kernel argument so the host can upload the .nv.global.init table (a global that size does not build)')
    return (ir ,layout ,data if layout else b'')

def llvm_type_size (ty :str ):
    ty =ty .strip ()
    m =re .match ('^\\[(\\d+) x (.+)\\]$',ty )or re .match ('^<(\\d+) x (.+)>$',ty )
    if m :
        el =llvm_type_size (m .group (2 ))
        return None if el is None else int (m .group (1 ))*el 
    if ty .endswith ('*'):
        return 8 
    m =re .match ('^i(\\d+)$',ty )
    if m :
        return (int (m .group (1 ))+7 )//8 
    return {'half':2 ,'bfloat':2 ,'float':4 ,'double':8 }.get (ty )
SPIRV_GENERIC =4 

def generic_pointers_to_addrspace4 (ir :str ,em :Emitter )->str :
    roots =set ()

    def repl (m ):
        lhs ,src ,ty =m .groups ()
        roots .add (lhs )
        return f'{lhs} = inttoptr {src} to {ty} addrspace({SPIRV_GENERIC})*'
    out =re .sub (f'^\\s*({VAL}) = inttoptr (i\\d+ {VAL}) to ([A-Za-z0-9_<>x\\[\\] ]+?)\\*$',lambda m :'  '+repl (m ),ir ,flags =re .M )

    def repl_cast (m ):
        lhs ,src ,ty =m .groups ()
        roots .add (lhs )
        return f'{lhs} = addrspacecast {src} to {ty} addrspace({SPIRV_GENERIC})*'
    out =re .sub (f'^\\s*({VAL}) = addrspacecast ([A-Za-z0-9_<>x\\[\\] ]+? addrspace\\(\\d+\\)\\* {VAL}) to ([A-Za-z0-9_<>x\\[\\] ]+?)\\*$',lambda m :'  '+repl_cast (m ),out ,flags =re .M )
    if not roots :
        return ir 
    em .note (f'{len(roots)} generic pointer(s) moved from addrspace 0 to addrspace {SPIRV_GENERIC} (NVVM generic is SPIR-V private)')
    return retype_pointer_chain (out ,roots ,SPIRV_GENERIC )

def rewrite_array_kernel_args (ir :str )->str :
    pat =re .compile ('^(define spir_kernel void @"[A-Za-z0-9_$.]+")\\((.*)\\)([^\\n]*)\\n(\\{\\n[A-Za-z0-9_$.]+:)',re .M )

    def full (m ):
        head ,params ,tail ,entry =m .groups ()
        parts =split_args (params )

        def aggregate (t ):
            return t .startswith ('[')and t .endswith (']')and (llvm_type_size (t )is not None )
        if not any ((aggregate (t )for t ,_ in parts )):
            return m .group (0 )
        new_params ,prologue =([],[])
        for ty ,val in parts :
            if not aggregate (ty ):
                new_params .append (f'{ty} {val}')
                continue 
            n =llvm_type_size (ty )
            words =(n +7 )//8 
            pad =words *8 
            stem =val [2 :-1 ]if val .startswith ('%"')else val [1 :]
            slot =f'%"{stem}.slot"'
            prologue .append (f'  {slot} = alloca [{pad} x i8], align 64')
            for i in range (words ):
                nm =f'%"{stem}.w{i}"'
                new_params .append (f'i64 {nm}')
                p =f'%"{stem}.p{i}"'
                pc =f'%"{stem}.pc{i}"'
                prologue .append (f'  {p} = getelementptr inbounds [{pad} x i8], [{pad} x i8]* {slot}, i64 0, i64 {i * 8}')
                prologue .append (f'  {pc} = bitcast i8* {p} to i64*')
                prologue .append (f'  store i64 {nm}, i64* {pc}, align 8')
            cast =f'%"{stem}.arr"'
            prologue .append (f'  {cast} = bitcast [{pad} x i8]* {slot} to {ty}*')
            prologue .append (f'  {val} = load {ty}, {ty}* {cast}, align 64')
        return f"{head}({', '.join(new_params)}){tail}\n{entry}\n"+'\n'.join (prologue )
    return pat .sub (full ,ir )
VAL ='(?:%"[^"]*"|%[\\w.$-]+|-?\\d+)'
_I128 ={'zext':re .compile (f'^({VAL}) = zext i32 ({VAL}) to i128$'),'shift':re .compile (f'^({VAL}) = (shl|lshr) i128 ({VAL}), (\\d+)$'),'or':re .compile (f'^({VAL}) = or i128 ({VAL}), ({VAL})$'),'trunc':re .compile (f'^({VAL}) = trunc i128 ({VAL}) to i32$')}
_LOAD =re .compile (f'^({VAL}) = load (volatile )?i128, (?:i128( addrspace\\(\\d+\\))?\\*|ptr( addrspace\\(\\d+\\))?) ({VAL})(.*)$')
_STORE =re .compile (f'^store (volatile )?i128 ({VAL}), (?:i128( addrspace\\(\\d+\\))?\\*|ptr( addrspace\\(\\d+\\))?) ({VAL})(.*)$')

def _derived (dst ,suffix ):
    return f'%"{dst[2:-1]}.{suffix}"'if dst .startswith ('%"')else f'{dst}.{suffix}'

def _bfloat_widths (ty ):
    m =re .match ('^<(\\d+) x bfloat>$',ty )
    if m :
        n =int (m .group (1 ))
        return (f'<{n} x i16>',f'<{n} x i32>',f'<{n} x float>',lambda v ,t :'<'+', '.join ([f'{t} {v}']*n )+'>')
    if ty =='bfloat':
        return ('i16','i32','float',lambda v ,t :v )
    return None 

def lower_bfloat_arithmetic (ir :str ,em :Emitter )->str :
    count =[0 ]

    def widen (dst ,tag ,ty ,val ,i16 ,i32 ,fty ,splat ,out ):
        b =_derived (dst ,tag +'b')
        z =_derived (dst ,tag +'z')
        h =_derived (dst ,tag +'h')
        f =_derived (dst ,tag +'f')
        out .append (f'  {b} = bitcast {ty} {val} to {i16}')
        out .append (f'  {z} = zext {i16} {b} to {i32}')
        out .append (f"  {h} = shl {i32} {z}, {splat('16', 'i32')}")
        out .append (f'  {f} = bitcast {i32} {h} to {fty}')
        return f 

    def repl (m ):
        indent ,dst ,op ,ty ,a ,b =m .groups ()
        shapes =_bfloat_widths (ty )
        if not shapes :
            return m .group (0 )
        i16 ,i32 ,fty ,splat =shapes 
        count [0 ]+=1 
        out =[]
        fa =widen (dst ,'a',ty ,a ,i16 ,i32 ,fty ,splat ,out )
        fb =widen (dst ,'b',ty ,b ,i16 ,i32 ,fty ,splat ,out )
        r =_derived (dst ,'r')
        ri =_derived (dst ,'ri')
        lsb =_derived (dst ,'lsb')
        bias =_derived (dst ,'bias')
        rnd =_derived (dst ,'rnd')
        sh =_derived (dst ,'sh')
        nar =_derived (dst ,'nar')
        out .append (f'  {r} = {op} {fty} {fa}, {fb}')
        out .append (f'  {ri} = bitcast {fty} {r} to {i32}')
        out .append (f"  {lsb} = lshr {i32} {ri}, {splat('16', 'i32')}")
        out .append (f"  {bias} = and {i32} {lsb}, {splat('1', 'i32')}")
        out .append (f"  {rnd} = add {i32} {ri}, {splat('32767', 'i32')}")
        out .append (f'  {sh} = add {i32} {rnd}, {bias}')
        out .append (f"  {nar} = lshr {i32} {sh}, {splat('16', 'i32')}")
        trunc =_derived (dst ,'t16')
        out .append (f'  {trunc} = trunc {i32} {nar} to {i16}')
        out .append (f'  {dst} = bitcast {i16} {trunc} to {ty}')
        return '\n'.join ((indent +line .strip ()for line in out ))
    out =re .sub (f'^(\\s*)({VAL}) = (fadd|fsub|fmul|fdiv) (bfloat|<\\d+ x bfloat>) ([^,\\n]+), ([^,\\n]+)$',repl ,ir ,flags =re .M )

    def repl_cmp (m ):
        indent ,dst ,pred ,ty ,a ,b =m .groups ()
        shapes =_bfloat_widths (ty )
        if not shapes :
            return m .group (0 )
        i16 ,i32 ,fty ,splat =shapes 
        count [0 ]+=1 
        out =[]
        fa =widen (dst ,'a',ty ,a ,i16 ,i32 ,fty ,splat ,out )
        fb =widen (dst ,'b',ty ,b ,i16 ,i32 ,fty ,splat ,out )
        out .append (f'  {dst} = fcmp {pred} {fty} {fa}, {fb}')
        return '\n'.join ((indent +line .strip ()for line in out ))
    out =re .sub (f'^(\\s*)({VAL}) = fcmp ([a-z]+) (bfloat|<\\d+ x bfloat>) ([^,\\n]+), ([^,\\n]+)$',repl_cmp ,out ,flags =re .M )
    if count [0 ]:
        em .note (f'{count[0]} bfloat arithmetic op(s) widened to f32 (SPIR-V has no bfloat)')
    return out 

def bfloat_as_i16 (ir :str ,em :Emitter )->str :
    if not re .search ('\\bbfloat\\b',ir ):
        return ir 
    left =re .findall ('^\\s*%\\S+ = (fadd|fsub|fmul|fdiv|frem|fcmp|fneg|fpext|fptrunc|sitofp|uitofp|fptosi|fptoui)\\b[^\\n]*bfloat',ir ,flags =re .M )
    if left :
        raise SystemExit (f'bfloat arithmetic left unlowered: {sorted(set(left))}')
    out =re .sub ('\\bbfloat\\b','i16',ir )
    alias ={}
    kept =[]
    for line in out .split ('\n'):
        m =re .match (f'^\\s*({VAL}) = bitcast (.+) ({VAL}) to (.+)$',line )
        if m and m .group (2 ).strip ()==m .group (4 ).strip ():
            alias [m .group (1 )]=alias .get (m .group (3 ),m .group (3 ))
            continue 
        kept .append (line )
    out ='\n'.join (kept )
    for dst ,src in alias .items ():
        out =re .sub (f'{re.escape(dst)}(?![\\w."])',src ,out )
    em .note ('bfloat spelled as i16 (SPIR-V bfloat needs an extension this module does not need)')
    return out 

def lower_fneg_bfloat (ir :str ,em :Emitter )->str :
    lanes ={}

    def repl (m ):
        indent ,dst ,ty ,src =m .groups ()
        n =1 
        vec =re .match ('^<(\\d+) x bfloat>$',ty )
        if vec :
            n =int (vec .group (1 ))
            ity =f'<{n} x i16>'
            mask ='<'+', '.join (['i16 -32768']*n )+'>'
        else :
            ity ='i16'
            mask ='-32768'
        lanes [dst ]=n 
        bits ,flip =(_derived (dst ,'bits'),_derived (dst ,'flip'))
        return f'{indent}{bits} = bitcast {ty} {src} to {ity}\n{indent}{flip} = xor {ity} {bits}, {mask}\n{indent}{dst} = bitcast {ity} {flip} to {ty}'
    out =re .sub (f'^(\\s*)({VAL}) = fneg (bfloat|<\\d+ x bfloat>) ({VAL})$',repl ,ir ,flags =re .M )
    if lanes :
        em .note (f'{len(lanes)} bfloat fneg(s) lowered to a sign-bit xor (SPIR-V has no bfloat)')
    return out 
_I128_COMPUTES =re .compile ('=\\s*(?:add|sub|mul|udiv|sdiv|urem|srem|shl|lshr|ashr|and|or|xor|icmp|select|phi|zext|sext|trunc|fptosi|fptoui|sitofp|uitofp|call)\\b[^\\n]*\\bi128\\b')

def legalize_i128 (ir :str ,em :Emitter )->str :
    if not _has_i128 (ir ):
        return ir 
    parts =re .split ('(?m)^(?=define )',ir )
    head ,functions =(parts [0 ],parts [1 :])
    if not functions :
        return _legalize_i128_function (ir ,em )
    out ,dropped =([head ],[])
    for fn in functions :
        if 'i128'not in fn :
            out .append (fn )
            continue 
        done =_legalize_i128_function (fn ,em )
        if not _has_i128 (done ):
            out .append (done )
            continue 
        if not _I128_COMPUTES .search (done ):
            out .append (_retype_i128 (done ,'<4 x i32>'))
            em .note ('an i128 used only as sixteen bytes of storage retyped to <2 x i64>')
            continue 
        m =re .match ('define[^@\\n]*@"?([^"(\\s]+)"?\\(',fn )
        dropped .append (m .group (1 )if m else '?')
        body ,brace ,tail =fn .partition ('\n}\n')
        if brace :
            out .append (tail )
    if dropped :
        text =''.join (out )
        for name in dropped :
            text =re .sub (f'(?m)^(![0-9]+) = (?:distinct )?!\\{{[^\\n]*@"?{re.escape(name)}"?[^\\n]*\\}}$','\\1 = !{}',text )
        out =[text ]
        em .note (f'{len(dropped)} of {len(functions)} function(s) dropped: 128-bit integers this cannot legalise, and leaving them in costs the whole module')
    return ''.join (out )

def _has_i128 (text :str )->bool :
    return re .search ('\\bi128\\b',_strip_quoted (text ))is not None 

def _strip_quoted (text :str )->str :
    return re .sub ('"[^"\\n]*"','""',text )

def _retype_i128 (text :str ,to :str )->str :
    out ,i =([],0 )
    for m in re .finditer ('"[^"\\n]*"',text ):
        out .append (re .sub ('\\bi128\\b',to ,text [i :m .start ()]))
        out .append (m .group (0 ))
        i =m .end ()
    out .append (re .sub ('\\bi128\\b',to ,text [i :]))
    return ''.join (out )

def _legalize_i128_function (ir :str ,em :Emitter )->str :
    if not _has_i128 (ir ):
        return ir 
    original =ir 
    lanes ={}
    blobs =set ()

    def _retype_signature (m ):
        line =m .group (0 )
        blobs .update (re .findall ('\\bi128 (%"[^"]+")',line ))
        return _retype_i128 (line ,'<4 x i32>')
    ir =re .sub ('(?m)^define[^\\n]*$',_retype_signature ,ir )
    out =[]
    for raw in ir .split ('\n'):
        s =raw .strip ()
        indent =raw [:len (raw )-len (raw .lstrip ())]
        m =_I128 ['zext'].match (s )
        if m :
            lanes [m .group (1 )]=[m .group (2 ),'0','0','0']
            continue 
        m =_I128 ['shift'].match (s )
        if m :
            dst ,op ,src ,amt =m .groups ()
            if src not in lanes or int (amt )%32 :
                return _i128_bail (original ,em ,s )
            n =int (amt )//32 
            src_lanes =lanes [src ]
            if op =='shl':
                lanes [dst ]=['0']*n +src_lanes [:4 -n ]
            else :
                lanes [dst ]=src_lanes [n :]+['0']*n 
            continue 
        m =_I128 ['or'].match (s )
        if m :
            dst ,a ,b =m .groups ()
            la =['0']*4 if a =='0'else lanes .get (a )
            lb =['0']*4 if b =='0'else lanes .get (b )
            if la is None or lb is None :
                return _i128_bail (original ,em ,s )
            merged =[]
            for x ,y in zip (la ,lb ):
                if x =='0':
                    merged .append (y )
                elif y =='0':
                    merged .append (x )
                else :
                    return _i128_bail (original ,em ,s )
            lanes [dst ]=merged 
            continue 
        m =_I128 ['trunc'].match (s )
        if m :
            dst ,src =m .groups ()
            if src not in lanes :
                return _i128_bail (original ,em ,s )
            lane0 =lanes [src ][0 ]
            out .append (f'{indent}{dst} = or i32 {lane0}, 0')
            continue 
        m =_LOAD .match (s )
        if m :
            dst ,vol ,as_typed ,as_opaque ,ptr ,tail =m .groups ()
            ptr_ty =f"<4 x i32>{as_typed or ''}*"if as_typed is not None else f"ptr{as_opaque or ''}"
            vec =derive (dst ,'.v4')
            out .append (f"{indent}{vec} = load {vol or ''}<4 x i32>, {ptr_ty} {ptr}{tail}")
            names =[]
            for i in range (4 ):
                nm =derive (dst ,f'.e{i}')
                out .append (f'{indent}{nm} = extractelement <4 x i32> {vec}, i32 {i}')
                names .append (nm )
            lanes [dst ]=names 
            continue 
        m =_STORE .match (s )
        if m :
            vol ,val ,as_typed ,as_opaque ,ptr ,tail =m .groups ()
            if val in blobs :
                ptr_ty =f"<4 x i32>{as_typed or ''}*"if as_typed is not None else f"ptr{as_opaque or ''}"
                out .append (f"{indent}store {vol or ''}<4 x i32> {val}, {ptr_ty} {ptr}{tail}")
                continue 
            if val not in lanes :
                return _i128_bail (original ,em ,s )
            ptr_ty =f"<4 x i32>{as_typed or ''}*"if as_typed is not None else f"ptr{as_opaque or ''}"
            cur ='undef'
            for i ,lane in enumerate (lanes [val ]):
                nm =derive (ptr ,f'.i{i}')
                out .append (f'{indent}{nm} = insertelement <4 x i32> {cur}, i32 {lane}, i32 {i}')
                cur =nm 
            out .append (f"{indent}store {vol or ''}<4 x i32> {cur}, {ptr_ty} {ptr}{tail}")
            continue 
        if re .search ('\\bto i128(?: addrspace\\(\\d+\\))?\\s*\\*',s ):
            out .append (_retype_i128 (raw ,'<4 x i32>'))
            continue 
        out .append (raw )
    ir ='\n'.join (out )
    ir =ir .replace ('i128 addrspace(','<4 x i32> addrspace(')
    ir =ir .replace ('i128*','<4 x i32>*')
    ir ='\n'.join ((_retype_i128 (line ,'<4 x i32>')if line .startswith ('!')and _has_i128 (line )else line for line in ir .split ('\n')))
    if _has_i128 (ir ):
        if os .environ .get ('ZLIFT_I128_DEBUG'):
            for line in ir .split ('\n'):
                if 'i128'in line :
                    print (f'  residual i128: {line.strip()[:120]}',file =sys .stderr )
        return _i128_bail (original ,em ,'residual i128 after legalisation')
    em .note ('128-bit vector memory rewritten to <4 x i32>')
    return ir 
_FPTO_SAT =re .compile (f'^(\\s*)({VAL}) = call i32 @"?llvm\\.fpto(s|u)i\\.sat\\.i32\\.f16"?\\(half ({VAL})\\)$',re .M )

def lower_fptosat_f16 (ir :str ,em :Emitter )->str :

    def repl (m ):
        indent ,dst ,signedness ,src =m .groups ()
        if signedness =='u':
            em .need ('llvm.maxnum.f16','half',['half','half'],spir =False )
            clamped =derive (dst ,'.cl')
            return f'{indent}{clamped} = call half @llvm.maxnum.f16(half {src}, half 0xH0000)\n{indent}{dst} = fptoui half {clamped} to i32'
        conv =derive (dst ,'.cv')
        nan =derive (dst ,'.nan')
        return f'{indent}{conv} = fptosi half {src} to i32\n{indent}{nan} = fcmp uno half {src}, {src}\n{indent}{dst} = select i1 {nan}, i32 0, i32 {conv}'
    out =_FPTO_SAT .sub (repl ,ir )
    if out !=ir :
        em .note ('llvm.fpto{s,u}i.sat.i32.f16 expanded (no SPIR-V legalisation)')
    return out 
ASM_IDIOM ={'elect.sync':('__zlift_elect_sync','i32',[])}
ASM_UNARY ={'rsqrt.approx.ftz.f64':('__zlift_rsqrt_approx_f64','double','double'),'rsqrt.approx.f64':('__zlift_rsqrt_approx_f64','double','double'),'rcp.approx.ftz.f64':('__zlift_rcp_approx_f64','double','double'),'rcp.approx.f64':('__zlift_rcp_approx_f64','double','double')}
for _ptx ,_cl in (('rp','rtp'),('rm','rtn'),('rz','rtz')):
    for _ity ,_llty in (('s32','i32'),('u32','i32'),('s64','i64'),('u64','i64')):
        ASM_UNARY [f'cvt.{_ptx}.f32.{_ity}']=(f'__zlift_cvt_{_cl}_{_ity}','float',_llty )
_ASM_LDMATRIX =re .compile (f'^(\\s*)({VAL}) = call \\{{ ?((?:i32,? ?)+)\\}} asm sideeffect "ldmatrix\\.sync\\.aligned\\.m8n8\\.x(\\d)(\\.trans)?\\.shared\\.b16[^"]*", "[^"]*"\\(i64 ({VAL})\\)$',re .M )
_ASM_STMATRIX =re .compile (f'^(\\s*)call void asm sideeffect "stmatrix\\.sync\\.aligned\\.x(\\d)\\.m8n8(\\.trans)?\\.shared\\.b16[^"]*", "[^"]*"\\(i64 ({VAL})((?:, i32 {VAL})+)\\)$',re .M )
_ASM_TMA =re .compile (f'^(\\s*)call void asm sideeffect "[^"]*cp\\.async\\.bulk\\.tensor\\.(\\d)d[^"]*", "[^"]*"\\((i64|i32) ({VAL}), i64 ({VAL}), (?:i64|i32) {VAL}((?:, i32 (?:{VAL}|\\d+))*)\\)$',re .M )
_ASM_CVTA_PARAM =re .compile (f'^(\\s*)({VAL}) = call i64 asm(?: sideeffect)?\\s*"\\{{[^"]*mov\\.b64 t, [A-Za-z0-9_$.]+_param_(\\d+); cvta\\.param\\.u64 \\$0, t;[^"]*\\}}", "[^"]*"\\(\\)$',re .M )
_ASM_ATOM_F16X2 =re .compile (f'^(\\s*)({VAL}) = call i32 asm sideeffect "atom\\.global\\.add\\.noftz\\.f16x2[^"]*", "[^"]*"\\(i64 ({VAL}), i32 ({VAL})\\)$',re .M )
_ASM_UNARY_CALL =re .compile (f'^(\\s*)({VAL}) = call (\\w+) asm(?: sideeffect)?\\s*"(.*?)", "[^"]*"\\((\\w+) ({VAL})\\)$',re .M )
_ASM_MBARRIER =re .compile (f'^(\\s*)(?:({VAL}) = )?call (?:void|i32) asm sideeffect "([^"]*(?:mbarrier|fence\\.proxy)[^"]*)", "[^"]*"\\(([^)]*)\\)$',re .M )
_ASM_WGMMA =re .compile (f'^(\\s*)({VAL}) = call (\\{{[^}}]*\\}}) asm sideeffect "wgmma\\.mma_async\\.sync\\.aligned\\.m64n(\\d+)k16\\.f32\\.f16\\.f16 [^"]*\\$\\d+, \\$\\d+, (\\d+), (-?\\d+), (-?\\d+), (\\d+), (\\d+);", "[^"]*"\\((.*)\\)$',re .M )
_ASM_WGMMA_SYNC =re .compile (f'^(\\s*)call void asm sideeffect "[^"]*wgmma\\.(?:fence|commit_group|wait_group)[^"]*", "[^"]*"\\(\\)$',re .M )
_ASM_MMA_SP =re .compile (f'^(\\s*)({VAL}) = call (\\{{[^}}]*\\}}) asm sideeffect "mma\\.sp\\.sync\\.aligned\\.m16n8k64\\.row\\.col\\.s32\\.s8\\.s8\\.s32[^"]*", "[^"]*"\\((.*)\\)$',re .M )
_ASM_CALL =re .compile (f'^(\\s*)({VAL}) = call (\\w+) asm sideeffect "(.*?)", "([^"]*)"\\(\\)$',re .M )

def lower_mma_sp (ir :str ,em :Emitter )->str :
    n =[0 ]
    name ='__zlift_mma_sp_m16n8k64_s32_s8'

    def repl (m ):
        indent ,dst ,ret ,args =m .groups ()
        ops =split_args (args )
        if len (ops )!=13 :
            return m .group (0 )
        n [0 ]+=1 
        em .need (name ,'<4 x i32>',['i32']*8 +['<4 x i32>','i32'],attrs =ATTR_CONVERGENT )
        em .note ('mma.sp m16n8k64 (2:4 sparse) emulated from the metadata')
        lines =[]
        cur ='undef'
        for i in range (4 ):
            nxt =derive (dst ,f'.c{i}')
            lines .append (f'{nxt} = insertelement <4 x i32> {cur}, i32 {ops[8 + i][1]}, i32 {i}')
            cur =nxt 
        res =derive (dst ,'.sp')
        lines .append (f'{res} = call spir_func <4 x i32> @{name}('+', '.join ((f'i32 {ops[i][1]}'for i in range (8 )))+f', <4 x i32> {cur}, i32 {ops[12][1]})')
        agg ='undef'
        for i in range (4 ):
            el =derive (dst ,f'.e{i}')
            lines .append (f'{el} = extractelement <4 x i32> {res}, i32 {i}')
            nxt =dst if i ==3 else derive (dst ,f'.s{i}')
            lines .append (f'{nxt} = insertvalue {ret} {agg}, i32 {el}, {i}')
            agg =nxt 
        return indent +('\n'+indent ).join (lines )
    return _ASM_MMA_SP .sub (repl ,ir )

def lower_wgmma (ir :str ,em :Emitter )->str :
    sm =re .search ('@"?shared_mem"? = [^\\n]*?global \\[(\\d+) x i8\\]',ir )
    if not sm :
        return ir 
    smty =f'[{sm.group(1)} x i8]'
    smbytes =int (sm .group (1 ))
    fn ='__zlift_wgmma_elem_f32_f16_f16'

    def repl (m ):
        indent ,dst ,ret ,n ,scale_d ,scale_a ,scale_b ,trans_a ,trans_b ,args =m .groups ()
        n =int (n )
        nregs =n //2 
        ops =split_args (args )
        if len (ops )<2 :
            return m .group (0 )
        desc_a ,desc_b =(ops [0 ][1 ],ops [1 ][1 ])
        acc_in =[o [1 ]for o in ops [2 :]]
        if trans_a !='0'or trans_b !='0':
            return m .group (0 )
        if scale_d !='0'and len (acc_in )!=nregs :
            return m .group (0 )
        em .need (fn ,'float',['ptr addrspace(3)','i32','i64','i32','i64','i32','i32','float'],attrs =ATTR_CONVERGENT )
        em .note (f'wgmma.mma_async m64n{n}k16 emulated from shared memory (no tensor cores)')
        lines =[]
        base =derive (dst ,'.smi')
        lines .append (f'{base} = ptrtoint {smty} addrspace(3)* @"shared_mem" to i64')
        b16 =derive (dst ,'.sm16')
        lines .append (f'{b16} = lshr i64 {base}, 4')
        bfld =derive (dst ,'.smf')
        lines .append (f'{bfld} = and i64 {b16}, 16383')
        offs ={}
        for tag ,desc in (('a',desc_a ),('b',desc_b )):
            f0 =derive (dst ,f'.{tag}f')
            lines .append (f'{f0} = and i64 {desc}, 16383')
            f1 =derive (dst ,f'.{tag}s')
            lines .append (f'{f1} = sub i64 {f0}, {bfld}')
            f2 =derive (dst ,f'.{tag}m')
            lines .append (f'{f2} = and i64 {f1}, 16383')
            f3 =derive (dst ,f'.{tag}o')
            lines .append (f'{f3} = shl i64 {f2}, 4')
            ok =derive (dst ,f'.{tag}k')
            lines .append (f'{ok} = icmp ult i64 {f3}, {smbytes}')
            f3s =derive (dst ,f'.{tag}c')
            lines .append (f'{f3s} = select i1 {ok}, i64 {f3}, i64 0')
            f4 =derive (dst ,f'.{tag}t')
            lines .append (f'{f4} = trunc i64 {f3s} to i32')
            offs [tag ]=f4 
        smp =derive (dst ,'.smp')
        lines .append (f'{smp} = bitcast {smty} addrspace(3)* @"shared_mem" to i8 addrspace(3)*')
        scale_ab =-1 if (scale_a =='-1')!=(scale_b =='-1')else 1 
        field =ret .strip ('{} ').split (',')[0 ].strip ()
        agg ='undef'
        if xmx_enabled ()and nregs %8 ==0 :
            ask =os .environ .get ('ZLIFT_XMX_ASK')
            tile =os .environ .get ('ZLIFT_XMX_FN','__zlift_wgmma_tile8_f32_f16_f16'if ask else '__zlift_wgmma_tile8_mem_f32_f16_f16')
            scratch_off =smbytes -XMX_SCRATCH_BYTES 
            tail =f'i32 {ask}'if ask else f'i32 {scratch_off}'if tile .endswith ('_mem_f32_f16_f16')else None 
            em .need (tile ,'<8 x float>',['ptr addrspace(3)','i32','i64','i32','i64','i32','i32','<8 x float>']+(['i32']if tail else []),attrs =ATTR_CONVERGENT )
            em .note (f'wgmma.mma_async m64n{n}k16 lowered to XMX ({nregs // 8} matrix-multiply pairs rather than {nregs} element loops)')
            for t in range (nregs //8 ):
                vin ='zeroinitializer'
                if scale_d !='0':
                    for j in range (8 ):
                        nv =derive (dst ,f'.t{t}i{j}')
                        lines .append (f'{nv} = insertelement <8 x float> {vin}, float {acc_in[t * 8 + j]}, i32 {j}')
                        vin =nv 
                res =derive (dst ,f'.t{t}')
                lines .append (f"{res} = call spir_func <8 x float> @{tile}(i8 addrspace(3)* {smp}, i32 {offs['a']}, i64 {desc_a}, i32 {offs['b']}, i64 {desc_b}, i32 {t}, i32 {scale_ab}, <8 x float> {vin}"+(f', {tail})'if tail else ')'))
                for j in range (8 ):
                    el =derive (dst ,f'.t{t}e{j}')
                    lines .append (f'{el} = extractelement <8 x float> {res}, i32 {j}')
                    idx =t *8 +j 
                    nxt =dst if idx ==nregs -1 else derive (dst ,f'.v{idx}')
                    lines .append (f'{nxt} = insertvalue {ret} {agg}, {field} {el}, {idx}')
                    agg =nxt 
            return indent +('\n'+indent ).join (lines )
        for i in range (nregs ):
            src =acc_in [i ]if scale_d !='0'else '0.000000e+00'
            el =derive (dst ,f'.w{i}')
            lines .append (f"{el} = call spir_func float @{fn}(i8 addrspace(3)* {smp}, i32 {offs['a']}, i64 {desc_a}, i32 {offs['b']}, i64 {desc_b}, i32 {i}, i32 {scale_ab}, float {src})")
            nxt =dst if i ==nregs -1 else derive (dst ,f'.v{i}')
            lines .append (f'{nxt} = insertvalue {ret} {agg}, {field} {el}, {i}')
            agg =nxt 
        return indent +('\n'+indent ).join (lines )
    out =_ASM_WGMMA .sub (repl ,ir )

    def repl_sync (m ):
        em .note ('wgmma fence/commit/wait replaced with a workgroup barrier (the multiply is synchronous here)')
        em .need ('_Z7barrierj','void',['i32'],attrs =ATTR_CONVERGENT )
        return f'{m.group(1)}call spir_func void @_Z7barrierj(i32 1)'
    return _ASM_WGMMA_SYNC .sub (repl_sync ,out )

def lower_inline_asm (ir :str ,em :Emitter )->str :

    def repl (m ):
        indent ,dst ,ret ,body ,constraints =m .groups ()
        for op ,(fn ,rty ,ptys )in ASM_IDIOM .items ():
            if op not in body :
                continue 
            if ret !=rty :
                continue 
            em .need (fn ,rty ,ptys ,attrs =ATTR_CONVERGENT )
            em .note (f'inline PTX `{op}` mapped to {fn}')
            return f'{indent}{dst} = call spir_func {rty} @{fn}()'
        return m .group (0 )

    def repl_cp_async (m ):
        indent ,size ,dst ,src ,srcsz =m .groups ()
        ty ={'4':'i32','8':'i64','16':'<4 x i32>'}.get (size )
        if ty is None :
            return m .group (0 )
        gp =derive (dst ,'.gsrc')
        sp =derive (dst ,'.sdst')
        v =derive (dst ,'.v')
        head =f'{indent}{gp} = inttoptr i64 {src} to {ty} addrspace(1)*\n{indent}{sp} = inttoptr i64 {dst} to {ty} addrspace(3)*\n'
        if srcsz is None :
            em .note (f'inline PTX `cp.async` ({size} bytes) done synchronously')
            return head +f'{indent}{v} = load {ty}, {ty} addrspace(1)* {gp}\n{indent}store {ty} {v}, {ty} addrspace(3)* {sp}'
        em .note (f'inline PTX `cp.async` ({size} bytes, guarded) done synchronously, zero-filling when the guard is false')
        stem =derive (dst ,'.cpa')[2 :-1 ]if dst .startswith ('%"')else dst [1 :]
        take ,fill ,done =(f'{stem}.take',f'{stem}.fill',f'{stem}.done')
        cond =derive (dst ,'.guard')
        zero ='zeroinitializer'if ty .startswith ('<')else '0'
        return head +f'{indent}{cond} = icmp ne i32 {srcsz}, 0\n{indent}br i1 {cond}, label %"{take}", label %"{fill}"\n"{take}":\n{indent}{v} = load {ty}, {ty} addrspace(1)* {gp}\n{indent}store {ty} {v}, {ty} addrspace(3)* {sp}\n{indent}br label %"{done}"\n"{fill}":\n{indent}store {ty} {zero}, {ty} addrspace(3)* {sp}\n{indent}br label %"{done}"\n"{done}":'
    ir =re .sub (f'^(\\s*)call void asm sideeffect "cp\\.async\\.[a-z.]*shared\\.global \\[\\$0\\], \\[\\$1\\], (\\d+)(?:, \\$2)?;", "[^"]*"\\(i64 ({VAL}), i64 ({VAL})(?:, i32 ({VAL}))?\\)$',repl_cp_async ,ir ,flags =re .M )

    def repl_ldmatrix (m ):
        indent ,dst ,fields ,tiles ,trans ,addr =m .groups ()
        n =int (tiles )
        if fields .count ('i32')!=n :
            return m .group (0 )
        suffix ='_trans'if trans else ''
        fn =f'__zlift_ldmatrix_x{n}{suffix}_b16'
        if n ==4 and trans and ('25632'in ir )and ('30001'in ir ):
            fn ='__zlift_ldmatrix_x4_mt88_fp8'
            em .note ('LDSM.16.MT88.4 feeding an fp8 byte de-interleave uses the byte-pair transpose the composition requires')
        rty ='i32'if n ==1 else f'<{n} x i32>'
        em .need (fn ,rty ,['ptr addrspace(3)'],attrs =ATTR_CONVERGENT )
        em .note (f'inline PTX `ldmatrix.x{n}{suffix}` emulated with sub-group shuffles')
        ptr =derive (dst ,'.p')
        vec =derive (dst ,'.v')
        lines =[f'{ptr} = inttoptr i64 {addr} to ptr addrspace(3)',f'{vec} = call spir_func {rty} @{fn}(ptr addrspace(3) {ptr})']
        agg_ty ='{'+', '.join (['i32']*n )+'}'
        agg ='undef'
        for i in range (n ):
            if n ==1 :
                el =vec 
            else :
                el =derive (dst ,f'.e{i}')
                lines .append (f'{el} = extractelement {rty} {vec}, i32 {i}')
            nxt =dst if i ==n -1 else derive (dst ,f'.s{i}')
            lines .append (f'{nxt} = insertvalue {agg_ty} {agg}, i32 {el}, {i}')
            agg =nxt 
        return indent +('\n'+indent ).join (lines )

    def repl_stmatrix (m ):
        indent ,tiles ,trans ,addr ,rest =m .groups ()
        regs =re .findall (f'i32 ({VAL})',rest )
        n =int (tiles )
        if len (regs )!=n :
            return m .group (0 )
        suffix ='_trans'if trans else ''
        fn =f'__zlift_stmatrix_x{n}{suffix}_b16'
        em .need (fn ,'void',['ptr addrspace(3)']+['i32']*n ,attrs =ATTR_CONVERGENT )
        em .note (f'inline PTX `stmatrix.x{n}{suffix}` emulated with sub-group shuffles')
        ptr =derive (addr ,'.stsm')
        argstr =', '.join ((f'i32 {r}'for r in regs ))
        return f'{indent}{ptr} = inttoptr i64 {addr} to ptr addrspace(3)\n{indent}call spir_func void @{fn}(ptr addrspace(3) {ptr}, {argstr})'

    def repl_cvta_param (m ):
        indent ,dst ,index =m .groups ()
        if index !='0':
            return m .group (0 )
        cm =re .search ('^@"?const_mem"?\\s*=[^\\n]*?(\\[\\d+ x \\[\\d+ x i8\\]\\])',ir ,re .M )
        if not cm :
            return m .group (0 )
        ty =cm .group (1 )
        em .note ('inline PTX `cvta.param` resolved to the marshalled parameter bank')
        gep =derive (dst ,'.param')
        return f'{indent}{gep} = getelementptr inbounds {ty}, {ty}* @"const_mem", i64 0, i64 0, i64 {SLIFTER_ARG_BASE}\n{indent}{dst} = ptrtoint i8* {gep} to i64'

    def repl_tma (m ):
        indent ,dims ,smem_ty ,smem ,desc ,coordstr =m .groups ()
        coords =re .findall (f'i32 ({VAL}|\\d+)',coordstr )
        if len (coords )<int (dims ):
            return m .group (0 )
        em .need ('__zlift_utma_load','void',['ptr addrspace(1)','ptr addrspace(3)','i32','i32','i32','i32','i32'],attrs =ATTR_CONVERGENT )
        em .note (f'inline PTX `cp.async.bulk.tensor.{dims}d` done as a cooperative copy (no TMA engine on Xe)')
        dptr =derive (smem ,'.tmadesc')
        sptr =derive (smem ,'.tmadst')
        off =derive (smem ,'.tmaoff')
        lines =[f'{dptr} = inttoptr i64 {desc} to ptr addrspace(1)',f'{sptr} = inttoptr {smem_ty} {smem} to ptr addrspace(3)']
        shname =re .search ('^@"?(\\w+)"?\\s*=[^\\n]*addrspace\\(3\\) global (\\[\\d+ x i8\\])',ir ,re .M )
        dyn =re .search ('= sub i32 %"[\\w.$]*winoff[\\w.$]*", (\\d+)',ir )
        if shname :
            base =derive (smem ,'.tmabase')
            rel =derive (smem ,'.tmarel')
            lines .append (f'{base} = ptrtoint {shname.group(2)} addrspace(3)* @"{shname.group(1)}" to i64')
            wide =derive (smem ,'.tmawide')
            if smem_ty =='i32':
                lines .append (f'{wide} = zext i32 {smem} to i64')
            else :
                lines .append (f'{wide} = add i64 {smem}, 0')
            lines .append (f'{rel} = sub i64 {wide}, {base}')
            trunc =derive (smem ,'.tmaoff32')
            lines .append (f'{trunc} = trunc i64 {rel} to i32')
            lines .append (f'{off} = add i32 {trunc}, {(dyn.group(1) if dyn else 0)}')
        else :
            lines .append (f'{off} = add i32 0, 0')
        c =(coords +['0','0','0','0'])[:4 ]
        lines .append (f'call spir_func void @__zlift_utma_load(ptr addrspace(1) {dptr}, ptr addrspace(3) {sptr}, i32 {off}, '+', '.join ((f'i32 {x}'for x in c ))+')')
        return indent +('\n'+indent ).join (lines )

    def repl_atom_f16x2 (m ):
        indent ,dst ,addr ,val =m .groups ()
        em .need ('__zlift_atom_add_f16x2','i32',['ptr addrspace(1)','i32'],attrs =ATTR_MEMORY )
        em .note ('inline PTX `atom.add.noftz.f16x2` done as a compare-and-swap loop (no packed-half atomic on Xe)')
        ptr =derive (dst ,'.p')
        return f'{indent}{ptr} = inttoptr i64 {addr} to ptr addrspace(1)\n{indent}{dst} = call spir_func i32 @__zlift_atom_add_f16x2(ptr addrspace(1) {ptr}, i32 {val})'

    def repl_unary (m ):
        indent ,dst ,ret ,body ,aty ,val =m .groups ()
        for op ,(fn ,rty ,pty )in ASM_UNARY .items ():
            if not body .startswith (op )or ret !=rty or aty !=pty :
                continue 
            em .need (fn ,rty ,[pty ])
            em .note (f'inline PTX `{op}` mapped to {fn}')
            return f'{indent}{dst} = call spir_func {rty} @{fn}({pty} {val})'
        return m .group (0 )

    def repl_mbarrier (m ):
        indent ,dst ,body ,argstr =m .groups ()
        args =split_args (argstr )if argstr .strip ()else []
        addrs =[v for t ,v in args if t =='i64']
        words =[v for t ,v in args if t =='i32']
        if 'fence.proxy'in body :
            em .note ('inline PTX `fence.proxy.async` lowered to a memory fence')
            return f'{indent}fence seq_cst'
        if not addrs :
            return m .group (0 )
        ptr =derive (addrs [0 ],'.bar')
        head =f'{indent}{ptr} = inttoptr i64 {addrs[0]} to ptr addrspace(3)\n'
        if 'mbarrier.init'in body :
            em .need ('__zlift_mbarrier_init','void',['ptr addrspace(3)','i32'],attrs =ATTR_CONVERGENT )
            em .note ('inline PTX `mbarrier.init` emulated in shared memory')
            return head +f'{indent}call spir_func void @__zlift_mbarrier_init(ptr addrspace(3) {ptr}, i32 {words[0]})'
        if 'mbarrier.try_wait'in body and dst :
            em .need ('__zlift_mbarrier_try_wait','i32',['ptr addrspace(3)','i32'],attrs =ATTR_CONVERGENT )
            em .note ('inline PTX `mbarrier.try_wait.parity` emulated in shared memory')
            return head +f'{indent}{dst} = call spir_func i32 @__zlift_mbarrier_try_wait(ptr addrspace(3) {ptr}, i32 {words[0]})'
        if 'mbarrier.arrive'in body :
            em .need ('__zlift_mbarrier_arrive','void',['ptr addrspace(3)'],attrs =ATTR_CONVERGENT )
            if 'expect_tx'in body :
                em .note ('inline PTX `mbarrier.arrive.expect_tx` treated as a plain arrival (every copy here is synchronous)')
            elif 'cluster'in body :
                em .note ('inline PTX `mbarrier.arrive` cluster form treated as CTA-local (one-CTA cluster)')
            else :
                em .note ('inline PTX `mbarrier.arrive` emulated in shared memory')
            return head +f'{indent}call spir_func void @__zlift_mbarrier_arrive(ptr addrspace(3) {ptr})'
        return m .group (0 )
    ir =_ASM_CVTA_PARAM .sub (repl_cvta_param ,ir )
    ir =_ASM_TMA .sub (repl_tma ,ir )
    ir =_ASM_MBARRIER .sub (repl_mbarrier ,ir )
    ir =_ASM_LDMATRIX .sub (repl_ldmatrix ,ir )
    ir =_ASM_STMATRIX .sub (repl_stmatrix ,ir )
    ir =_ASM_ATOM_F16X2 .sub (repl_atom_f16x2 ,ir )
    ir =_ASM_UNARY_CALL .sub (repl_unary ,ir )
    return _ASM_CALL .sub (repl ,ir )

def narrow_widened_stores (ir :str ,em :Emitter )->str :
    defs ={}
    for m in re .finditer (f'^\\s*({VAL}) = zext (i8|i16) ({VAL}) to i32$',ir ,re .M ):
        defs [m .group (1 )]=(m .group (2 ),m .group (3 ))
    casts ={}
    for m in re .finditer (f'^\\s*({VAL}) = bitcast i32 ({VAL}) to float$',ir ,re .M ):
        if m .group (2 )in defs :
            casts [m .group (1 )]=defs [m .group (2 )]
    if not casts :
        return ir 

    def repl (m ):
        indent ,val ,space ,ptr =m .groups ()
        if val not in casts :
            return m .group (0 )
        ty ,src =casts [val ]
        sp =space or ''
        cast =derive (ptr ,'.narrow')
        em .note (f'32-bit store of a widened {ty} narrowed back (CuLifter models registers as 32 bits)')
        return f'{indent}{cast} = bitcast float{sp}* {ptr} to {ty}{sp}*\n{indent}store {ty} {src}, {ty}{sp}* {cast}'
    return re .sub (f'^(\\s*)store float ({VAL}), float( addrspace\\(\\d+\\))?\\* ({VAL})\\s*$',repl ,ir ,flags =re .M )
_CMPXCHG =re .compile (f'^({VAL}) = cmpxchg (?:weak )?(?:volatile )?(?:i32 addrspace\\((\\d+)\\)\\*|ptr addrspace\\((\\d+)\\)) ({VAL}), i32 ({VAL}), i32 ({VAL})\\s.*$')
_EXTRACT =re .compile (f'^({VAL}) = extractvalue \\{{ ?i32, ?i1 ?\\}} ({VAL}), (0|1)$')
CAS_BUILTIN ={'1':'_Z14atomic_cmpxchgPU3AS1Viii','3':'_Z14atomic_cmpxchgPU3AS3Viii'}

def retype_integer_atomics (ir :str ,em :Emitter )->str :
    ops =('xchg','add','sub','and','nand','or','xor','max','min','umax','umin')
    width ={'float':'i32','double':'i64','half':'i16','bfloat':'i16'}
    n =[0 ]

    def repl (m ):
        indent ,dst ,op ,fty ,space ,ptr ,vty ,val ,tail =m .groups ()
        if op not in ops or fty not in width or fty !=vty :
            return m .group (0 )
        ity =width [fty ]
        n [0 ]+=1 
        pi =derive (dst ,'.aptr')
        vi =derive (dst ,'.aval')
        ri =derive (dst ,'.ares')
        return '\n'.join ([f'{indent}{pi} = bitcast {fty} {space}* {ptr} to {ity} {space}*',f'{indent}{vi} = bitcast {fty} {val} to {ity}',f'{indent}{ri} = atomicrmw {op} {ity} {space}* {pi}, {ity} {vi}{tail}',f'{indent}{dst} = bitcast {ity} {ri} to {fty}'])
    out =re .sub (f'^(\\s*)({VAL}) = atomicrmw (\\w+) (\\w+) (addrspace\\(\\d+\\))\\* ({VAL}), (\\w+) ({VAL})([^\\n]*)$',repl ,ir ,flags =re .M )
    if n [0 ]:
        em .note (f'{n[0]} integer atomic(s) given integer operands (the lifter had typed the value as floating point)')
    return out 

def lower_atomic_fadd (ir :str ,em :Emitter )->str :
    n =[0 ]

    def repl (m ):
        indent ,dst ,ptr ,val =m .groups ()
        n [0 ]+=1 
        em .need ('__zlift_atomic_fadd_global','float',['ptr addrspace(1)','float'],attrs =ATTR_CONVERGENT )
        return f'{indent}{dst} = call spir_func float @__zlift_atomic_fadd_global(ptr addrspace(1) {ptr}, float {val})'
    out =re .sub (f'^(\\s*)({VAL}) = atomicrmw fadd (?:ptr addrspace\\(1\\)|float addrspace\\(1\\)\\*) ({VAL}), float ({VAL})(?:[^\\n]*)$',repl ,ir ,flags =re .M )
    if n [0 ]:
        em .note (f'{n[0]} atomicrmw fadd lowered to a compare-exchange loop (the SPIR-V atomic-float extension does not arrive)')
    return out 

def lower_cmpxchg (ir :str ,em :Emitter )->str :
    if 'cmpxchg'not in ir :
        return ir 
    olds ={}
    out =[]
    for raw in ir .split ('\n'):
        s =raw .strip ()
        indent =raw [:len (raw )-len (raw .lstrip ())]
        m =_CMPXCHG .match (s )
        if m :
            dst ,space_typed ,space_opaque ,ptr ,cmp_v ,new_v =m .groups ()
            space =space_typed or space_opaque 
            if space not in CAS_BUILTIN :
                out .append (raw )
                continue 
            fn =CAS_BUILTIN [space ]
            ptr_ty =f'i32 addrspace({space})*'if space_typed else f'ptr addrspace({space})'
            em .need (fn ,'i32',[ptr_ty ,'i32','i32'],attrs =ATTR_MEMORY )
            old =derive (dst ,'.old')
            olds [dst ]=(old ,cmp_v )
            out .append (f'{indent}{old} = call spir_func i32 @{fn}({ptr_ty} {ptr}, i32 {cmp_v}, i32 {new_v})')
            continue 
        m =_EXTRACT .match (s )
        if m and m .group (2 )in olds :
            dst ,src ,field =m .groups ()
            old ,cmp_v =olds [src ]
            if field =='0':
                out .append (f'{indent}{dst} = or i32 {old}, 0')
            else :
                out .append (f'{indent}{dst} = icmp eq i32 {old}, {cmp_v}')
            continue 
        out .append (raw )
    if olds :
        em .note ('cmpxchg lowered to the OpenCL atomic_cmpxchg builtin')
    return '\n'.join (out )

def _i128_bail (ir_original :str ,em :Emitter ,why :str )->str :
    em .note (f'i128 legalisation skipped, llc will reject the module: {why}')
    return ir_original 

def rewrite_metadata (ir :str ,em :Emitter )->str :
    ir =re .sub ('^!nvvmir\\.version\\s*=.*$','',ir ,flags =re .M )
    ir =re .sub ('^!nvvm\\.annotations\\s*=.*$','',ir ,flags =re .M )
    present =set (re .findall ('^declare .*@"?([A-Za-z0-9_.$]+)"?\\(',ir ,re .M ))
    decls =''.join ((d +'\n'for name ,d in sorted (em .decls .items ())if name not in present ))
    if decls :
        used =sorted ({a for a in ATTR_GROUPS if a in decls })
        decls +='\n'+''.join ((f'attributes {a} = {ATTR_GROUPS[a]}\n'for a in used ))
        ir =re .sub ('^(target datalayout.*)$','\\1\\n\\n'+decls .rstrip (),ir ,count =1 ,flags =re .M )
    extra =[f'!opencl.ocl.version = !{{ !{MD_OCL_VERSION} }}',f'!opencl.spir.version = !{{ !{MD_OCL_VERSION} }}',f'!{MD_OCL_VERSION} = !{{ i32 3, i32 0 }}',f'!{MD_SUBGROUP_SIZE} = !{{ i32 {WARP_SIZE} }}']
    return ir .rstrip ()+'\n\n'+'\n'.join (extra )+'\n'
LLVM_TYPE_BYTES ={'i1':1 ,'i8':1 ,'i16':2 ,'i32':4 ,'i64':8 ,'half':2 ,'float':4 ,'double':8 ,'ptr':8 }

def write_arg_layout (ir :str ,path :str ,const_mem =None ,nv_global =None ,nv_global_init =None ,nv_init_data =None )->None :
    import json 
    out ={}
    for m in re .finditer ('^define spir_kernel void @"?([A-Za-z0-9_$.]+)"?\\((.*)\\)',ir ,re .M ):
        name ,params =(m .group (1 ),m .group (2 ))
        args =[]
        for ty ,val in split_args (params ):
            stem =val [2 :-1 ]if val .startswith ('%"')else val .lstrip ('%')
            if stem in ('const_mem_arg','__slifter_nv_global_arg','__slifter_nv_global_init_arg'):
                continue 
            if stem in (TILE_ARG ,GRID_ARG ):
                args .append ({'offset':65535 if stem ==TILE_ARG else 65534 ,'size':4 ,'type':'i32'})
                continue 
            om =re .match ('^arg_(\\d+)(?:\\.w(\\d+))?$',stem )
            am =re .match ('^\\[(\\d+) x i8\\]$',ty )
            vm =re .match ('^<(\\d+) x ([a-z]\\w*)>$',ty .strip ())
            if am :
                size =int (am .group (1 ))
            elif vm :
                lane =LLVM_TYPE_BYTES .get (vm .group (2 ))
                size =int (vm .group (1 ))*lane if lane else None 
            else :
                size =LLVM_TYPE_BYTES .get (ty .strip ())
            offset =None 
            if om :
                offset =int (om .group (1 ))
                if om .group (2 ):
                    offset +=8 *int (om .group (2 ))
            args .append ({'offset':offset ,'size':size ,'type':ty .strip ()})
        out [name ]=args 
    shm =re .search ('^@"?([A-Za-z0-9_$.]*shared[A-Za-z0-9_$.]*)"?\\s*=\\s*(?:internal )?addrspace\\(1\\) global \\[(\\d+) x i8\\]',ir ,re .M )
    if shm :
        out ['__shared__']={'bytes':int (shm .group (2 ))-SHM_GUARD_BYTES ,'guard_bytes':SHM_GUARD_BYTES ,'name':shm .group (1 ),'in_global':True }
    if const_mem :
        out ['__const_mem__']=const_mem 
    if nv_global :
        out ['__nv_global__']=nv_global 
    if nv_global_init :
        blob =re .sub ('\\.args\\.json$','',path )+'.nvglobal.bin'
        with open (blob ,'wb')as f :
            f .write (nv_init_data or b'')
        out ['__nv_global_init__']=dict (nv_global_init ,file =blob )
    with open (path ,'w')as f :
        json .dump (out ,f ,indent =2 )

def opt_passes (ll_path ):
    with open (ll_path )as f :
        ir =f .read ()
    names =re .findall ('^define[^@\\n]*\\bspir_kernel\\b[^@\\n]*@"?([^"(\\s]+)"?\\(',ir ,re .M )
    if not names :
        return ['--passes=always-inline,globaldce']
    return ['--passes=internalize,always-inline,globaldce','--internalize-public-api-list='+','.join (names )]

def translate (ir :str ,shared_bytes :int =32768 ):
    kernels =parse_kernels (ir )
    if not kernels :
        print ('warning: no !nvvm.annotations kernel marker found',file =sys .stderr )
    em =Emitter ()
    ir =rewrite_header (ir )
    ir =rewrite_module_globals (ir )
    ir =define_shared_memory (ir ,em ,shared_bytes )
    ir =rewrite_sregs (ir ,em )
    ir =rewrite_intrinsics (ir ,em )
    ir =legalize_i128 (ir ,em )
    ir =retype_integer_atomics (ir ,em )
    ir =lower_atomic_fadd (ir ,em )
    ir =lower_cmpxchg (ir ,em )
    ir =lower_mma_sp (ir ,em )
    ir =lower_wgmma (ir ,em )
    ir =lower_inline_asm (ir ,em )
    ir =lower_fptosat_f16 (ir ,em )
    ir =lower_fneg_bfloat (ir ,em )
    ir =lower_bfloat_arithmetic (ir ,em )
    ir =bfloat_as_i16 (ir ,em )
    ir =narrow_widened_stores (ir ,em )
    ir =generic_pointers_to_addrspace4 (ir ,em )
    ir =drop_dead_declares (ir )
    ir =drop_unresolvable_calls (ir ,em )
    ir =rewrite_kernel_defs (ir ,kernels ,em )
    if tiling_enabled ():
        ir =re .sub ('^(define spir_kernel void @"?[A-Za-z0-9_$.]+"?)\\((.*)\\)([^\\n]*)$',lambda m :f'''{m.group(1)}({m.group(2)}{(', ' if m.group(2).strip() else '')}i32 %"{TILE_ARG}", i32 %"{GRID_ARG}"){m.group(3)}''',ir ,flags =re .M )
        em .note ('every kernel takes a block-index offset (ZLIFT_TILE_ARG)')
    ir ,const_mem_layout =const_mem_to_argument (ir ,em )
    ir ,nv_global_layout =nv_global_to_argument (ir ,em )
    ir ,nv_init_layout ,nv_init_data =nv_global_init_to_argument (ir ,em )
    ir =rewrite_array_kernel_args (ir )
    ir =rewrite_metadata (ir ,em )
    if os .environ .get ('ZLIFT_SUBGROUP_PIN')=='auto'and (not _uses_warp_op (ir )):
        em .note ('sub-group width left to the device: no warp-level operation in the finished module (ZLIFT_SUBGROUP_PIN=auto)')
        ir =re .sub (f' !intel_reqd_sub_group_size !{MD_SUBGROUP_SIZE}\\b','',ir )
    return (ir ,em ,kernels ,(const_mem_layout ,nv_global_layout ,nv_init_layout ,nv_init_data ))

def main ():
    ap =argparse .ArgumentParser (description =__doc__ ,formatter_class =argparse .RawDescriptionHelpFormatter )
    ap .add_argument ('input',nargs ='?')
    ap .add_argument ('-o','--output')
    ap .add_argument ('--shared-bytes',type =int ,default =int (os .environ .get ('ZLIFT_SHARED_BYTES',32768 )))
    ap .add_argument ('--quiet',action ='store_true')
    ap .add_argument ('--emit-args',metavar ='FILE')
    ap .add_argument ('--print-exts',action ='store_true')
    args =ap .parse_args ()
    if args .print_exts :
        print ('--spirv-ext='+','.join (('+'+e for e in SPIRV_EXTS )))
        return 
    if not args .input or not args .output :
        ap .error ('input and -o are required')
    with open (args .input )as f :
        ir =f .read ()
    ir ,em ,kernels ,layout =translate (ir ,args .shared_bytes )
    with open (args .output ,'w')as f :
        f .write (ir )
    print (f"kernels: {', '.join(sorted(kernels)) or '(none)'}",file =sys .stderr )
    leftover =sorted (set (re .findall ('@"?(llvm\\.nvvm\\.[A-Za-z0-9_.]+)"?\\(',ir )))
    if leftover :
        print ('unlowered nvvm intrinsics: '+', '.join (leftover ),file =sys .stderr )
    if args .emit_args :
        write_arg_layout (ir ,args .emit_args ,*layout )
    if em .notes and (not args .quiet ):
        print ('approximations:',file =sys .stderr )
        for note ,n in sorted (em .notes .items ()):
            print (f'  [x{n}] {note}',file =sys .stderr )
if __name__ =='__main__':
    main ()
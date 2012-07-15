#include "ir.hh"

#include <iostream>
#include <iomanip>

#include <string.h>

_START_LAMBDACHINE_NAMESPACE

using namespace std;

uint8_t IR::mode_[k_MAX + 1] = {
#define IRMODE(name, flags, left, right) \
  (((IRM##left) | ((IRM##right) << 2)) | IRM_##flags),
  IRDEF(IRMODE)
#undef IRMODE
  0
};

#define STR(x) #x

const char *IR::name_[k_MAX + 1] = {
#define IRNAME(name, flags, left, right) STR(name),
  IRDEF(IRNAME)
#undef IRNAME
  "???"
};

static const char *tyname[] = {
#define IRTNAME(name, str, col) str,
  IRTDEF(IRTNAME)
#undef IRTNAME
};

enum {
  TC_NONE, TC_PRIM, TC_HEAP, TC_GREY,
  TC_MAX
};

static const uint8_t tycolor[] = {
#define IRTCOLOR(name, str, col) TC_##col,
  IRTDEF(IRTCOLOR)
#undef IRTCOLOR
};

static const char *tycolorcode[TC_MAX] = {
  "", COL_PURPLE, COL_RED, COL_GREY
};

void IR::printIRRef(std::ostream &out, IRRef ref) {
  if (ref < REF_BIAS) {
    out << 'K' << right << setw(3) << dec << setfill('0')
        << (int)(REF_BIAS - ref);
  } else {
    out << right << setw(4) << dec << setfill('0') << (int)(ref - REF_BIAS);
  }
}

static void printArg(ostream &out, uint8_t mode, uint16_t op, IR *ir, IRBuffer *buf) {
  switch ((IR::Mode)mode) {
  case IR::IRMnone:
    break;
  case IR::IRMref:
    out << ' ';
    IR::printIRRef(out, (IRRef)op);
    break;
  case IR::IRMlit:
    out << " #";
    out << setw(3) << setfill(' ') << left << (unsigned int)op;
    break;
  case IR::IRMcst:
    if (ir->opcode() == IR::kKINT) {
      int32_t i = ir->i32();
      char sign = (i < 0) ? '-' : '+';
      uint32_t k = (i < 0) ? -i : i;
      out << ' ' << COL_PURPLE << sign << k << COL_RESET;
    } else if (ir->opcode() == IR::kKWORD && buf != NULL) {
      out << ' ' << COL_BLUE "0x" << hex << buf->kword(ir->u32()) << dec
          << COL_RESET;
    } else {
        out << "<cst>";
    }
    break;
  default:
    break;
  }
}

void IR::debugPrint(ostream &out, IRRef self, IRBuffer *buf) {
  IR::Opcode op = opcode();
  uint8_t ty = t() & IRT_TYPE;
  IR::printIRRef(out, self);
  out << "    "; // TODO: flags go here
  out << tycolorcode[tycolor[ty]];
  out << tyname[ty] << COL_RESET << ' ';
  out << setw(8) << setfill(' ') << left << name_[op];
  uint8_t mod = mode(op);
  printArg(out, mod & 3, op1(), this, buf);
  printArg(out, (mod >> 2) & 3, op2(), this, buf);
  out << endl;
}

void IRBuffer::debugPrint(ostream &out, int traceNo) {
  out << "---- TRACE " << right << setw(4) << setfill('0') << traceNo 
      << " IR -----------" << endl;
  for (IRRef ref = bufmin_; ref < bufmax_; ++ref) {
    ir(ref)->debugPrint(out, ref, this);
  }
}

IRBuffer::IRBuffer(Word *base, Word *top)
  : size_(1024), slots_(base, top), kwords_() {
  realbuffer_ = new IR[size_];

  size_t nliterals = size_ / 4;

  bufstart_ = REF_BIAS - nliterals;
  bufend_ = bufstart_ + size_;

  // We want to have:
  //
  //     buffer_[REF_BIAS] = realbuffer_[nliterals];
  //
  // Thus:
  //
  //     buffer_ + REF_BIAS = realbuffer_ + nliterals
  //
  buffer_ = realbuffer_ + (nliterals - REF_BIAS);
  bufmin_ = REF_BIAS;
  bufmax_ = REF_BIAS;

  emitRaw(IRT(IR::kBASE, IRT_PTR), 0, 0);
  memset(chain_, 0, sizeof(chain_));
}

IRBuffer::~IRBuffer() {
  delete[] realbuffer_;
  realbuffer_ = NULL;
  buffer_ = NULL;
}

void IRBuffer::growTop() {
  cerr << "NYI: Growing IR buffer\n";
  exit(3);
}

void IRBuffer::growBottom() {
  cerr << "NYI: Growing IR buffer\n";
  exit(3);
}

TRef IRBuffer::emit() {
  IRRef ref = nextIns();
  IR *ir1 = ir(ref);
  IR::Opcode op = fold_.ins.opcode();

  ir1->setPrev(chain_[op]);
  chain_[op] = (IRRef1)ref;

  ir1->setOpcode(op);
  ir1->setOp1(fold_.ins.op1());
  ir1->setOp2(fold_.ins.op2());
  IR::Type t = fold_.ins.t();
  ir1->setT(t);

  return TRef(ref, t);
}

TRef IRBuffer::literal(IRType ty, uint64_t lit) {
  IRRef ref;
  if (checki32(lit)) {
    int32_t k = (int32_t)lit;
    for (ref = chain_[IR::kKINT]; ref != 0; ref = buffer_[ref].prev()) {
      if (buffer_[ref].data_.i == k && (buffer_[ref].data_.t & IRT_TYPE) == ty)
        goto found;
    }
    ref = nextLit();  // Invalidates any IR*!
    IR *tir = ir(ref);
    tir->data_.i = k;
    tir->data_.t = (uint8_t)ty;
    tir->data_.o = IR::kKINT;
    tir->data_.prev = chain_[IR::kKINT];
    chain_[IR::kKINT] = (IRRef1)ref;
    return TRef(ref, ty);
  } else {
    for (ref = chain_[IR::kKWORD]; ref != 0; ref = buffer_[ref].prev()) {
      if ((buffer_[ref].data_.t & IRT_TYPE) == ty &&
          kwords_[buffer_[ref].data_.u] == lit)
        goto found;
    }
    ref = nextLit();  // Invalidates any IR*!
    IR *tir = ir(ref);
    kwords_.push_back(lit);
    tir->data_.u = kwords_.size() - 1;
    tir->data_.t = (uint8_t)ty;
    tir->data_.o = IR::kKWORD;
    tir->data_.prev = chain_[IR::kKWORD];
    chain_[IR::kKWORD] = (IRRef1)ref;
    return TRef(ref, ty);
  }
 found:
  return TRef(ref, ty);
}

TRef IRBuffer::optFold() {
  IR::Opcode op = fins()->opcode();
  IR::IRMode irmode = IR::mode(op);
  if (op == IR::kSLOAD) {

  } else if ((irmode & IR::IRM_S) == IR::IRM_N) {
    // If it's not a store/load/alloc, do CSE.
    return optCSE();
  }
  // TODO: Currently no other optimisations are performed
  return emit();
}

TRef IRBuffer::optCSE() {
  IRRef2 op12 =
    (IRRef2)fins()->op1() + ((IRRef2)fins()->op2() << 16);
  IR::Opcode op = fins()->opcode();
  if (true /* TODO: check if CSE is enabled */) {
    IRRef ref = chain_[op];
    IRRef lim = fins()->op1();
    if (fins()->op2() > lim) lim = fins()->op2();

    while (ref > lim) {
      if (ir(ref)->op12() == op12) {
        // Common subexpression found
        return TRef(ref, ir(ref)->t());
      }
      ref = ir(ref)->prev();
    }
  }
  // Otherwise emit IR
  return emit();
}

AbstractStack::AbstractStack(Word *base, Word *top) {
  slots_ = new TRef[kSlots];
  base_ = kInitialBase;
  LC_ASSERT(base < top);
  realOrigBase_ = base;
  top_ = base_ + (top - base);
  LC_ASSERT(top_ < kSlots);
  low_ = base_;
  high_ = top_;
}

bool AbstractStack::frame(Word *base, Word *top) {
  int delta = base - realOrigBase_;
  if (delta < -(kInitialBase - 1)) return false;  // underflow
  base_ = kInitialBase + delta;
  top_ = base_ + (top - base);
  if (top_ >= kSlots) return false; // overflow
  return true;
}

_END_LAMBDACHINE_NAMESPACE
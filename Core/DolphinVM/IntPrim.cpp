#include "Ist.h"

#ifndef _DEBUG
#pragma optimize("s", on)
#pragma auto_inline(off)
#endif

#include "ObjMem.h"
#include "Interprt.h"
#include "InterprtPrim.inl"

template <class Cmp, bool Lt> __forceinline Oop* primitiveIntegerCmp(Oop* const sp, const Cmp& cmp)
{
	// Normally it is better to jump on the failure case as the static prediction is that forward
	// jumps are not taken, but these primitives are normally only invoked when the special bytecode 
	// has triggered the fallback method (unless performed), which suggests the arg will not be a 
	// SmallInteger, so the 99% case is that the primitive should fail
	Oop arg = *sp;
	if (!ObjectMemoryIsIntegerObject(arg))
	{
		LargeIntegerOTE* oteArg = reinterpret_cast<LargeIntegerOTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			// Whether a SmallIntegers is greater than a LargeInteger depends on the sign of the LI
			// - All normalized negative LIs are less than all SmallIntegers
			// - All normalized positive LIs are greater than all SmallIntegers
			// So if sign bit of LI is not set, receiver is < arg
			*(sp - 1) = reinterpret_cast<Oop>((oteArg->m_location->signBit(oteArg) ? Lt : !Lt) ? Pointers.True : Pointers.False);
			return sp - 1;
		}
		else
			return nullptr;
	}
	else
	{
		Oop receiver = *(sp - 1);
		// We can perform the comparisons without shifting away the SmallInteger bit since it always 1
		*(sp - 1) = reinterpret_cast<Oop>(cmp(static_cast<SMALLINTEGER>(receiver), static_cast<SMALLINTEGER>(arg)) ? Pointers.True : Pointers.False);
		return sp - 1;
	}
}

Oop* __fastcall Interpreter::primitiveLessThan(Oop* const sp, unsigned)
{
	return primitiveIntegerCmp<std::less<SMALLINTEGER>, false>(sp, std::less<SMALLINTEGER>());
}

Oop* __fastcall Interpreter::primitiveLessOrEqual(Oop* const sp, unsigned)
{
	return primitiveIntegerCmp<std::less_equal<SMALLINTEGER>, false>(sp, std::less_equal<SMALLINTEGER>());
}

Oop* __fastcall Interpreter::primitiveGreaterThan(Oop* const sp, unsigned)
{
	return primitiveIntegerCmp<std::greater<SMALLINTEGER>, true>(sp, std::greater<SMALLINTEGER>());
}

Oop* __fastcall Interpreter::primitiveGreaterOrEqual(Oop* const sp, unsigned)
{
	return primitiveIntegerCmp<std::greater_equal<SMALLINTEGER>, true>(sp, std::greater_equal<SMALLINTEGER>());
}

Oop* __fastcall Interpreter::primitiveEqual(Oop* const sp, unsigned)
{
	Oop arg = *sp;
	if (!ObjectMemoryIsIntegerObject(arg))
	{
		OTE* oteArg = reinterpret_cast<OTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			// LargeIntegers and Integers are never equal
			*(sp - 1) = reinterpret_cast<Oop>(Pointers.False);
			return sp - 1;
		}
		else
			return nullptr;
	}
	else
	{
		Oop receiver = *(sp - 1);
		// We can perform the comparisons without shifting away the SmallInteger bit since it always 1
		*(sp - 1) = reinterpret_cast<Oop>(receiver == arg ? Pointers.True : Pointers.False);
		return sp - 1;
	}
}

//////////////////////////////////////////////////////////////////////////////;
// SmallInteger Bit Manipulation Primitives

template <class P> __forceinline static Oop* primitiveIntegerOp(Oop* const sp, const P &op)
{
	Oop arg = *sp;
	if (!ObjectMemoryIsIntegerObject(arg))
		return nullptr;

	Oop receiver = *(sp - 1);
	*(sp - 1) = op(receiver, arg);
	return sp - 1;
}

Oop* __fastcall Interpreter::primitiveBitAnd(Oop* const sp, unsigned)
{
	return primitiveIntegerOp(sp, std::bit_and<Oop>());
}

Oop* __fastcall Interpreter::primitiveBitOr(Oop* const sp, unsigned)
{
	return primitiveIntegerOp(sp, std::bit_or<Oop>());
}

Oop* __fastcall Interpreter::primitiveBitXor(Oop* const sp, unsigned)
{
	struct bit_xor {
		Oop operator() (const Oop& receiver, const Oop& arg) const {
			return receiver ^ (arg - 1);
		}
	};

	return primitiveIntegerOp(sp, bit_xor());
}

Oop* __fastcall Interpreter::primitiveAnyMask(Oop* const sp, unsigned)
{
	Oop receiver = *(sp - 1);
	Oop arg = *sp;
	if (ObjectMemoryIsIntegerObject(arg))
	{
		// We can perform the comparisons without shifting away the SmallInteger bit since it always 1
		*(sp - 1) = reinterpret_cast<Oop>((receiver & arg) != ZeroPointer ? Pointers.True : Pointers.False);
		return sp - 1;
	}
	else
	{
		LargeIntegerOTE* oteArg = reinterpret_cast<LargeIntegerOTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			// If receiver -ve allMask could be true, depending on comparison with bottom limb
			// If receiver +ve, can never be true
			SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
			uint32_t* digits = oteArg->m_location->m_digits;
			if ((r & digits[0]) != 0)
			{
				// One or more bits are set in the first limb of the LI and in the SmallInteger
				*(sp - 1) = reinterpret_cast<Oop>(Pointers.True);
				return sp - 1;
			}
			else
			{
				if (r < 0)
				{
					for (MWORD i = oteArg->getWordSize()-1; i > 0; i--)
					{
						if (digits[i] != 0)
						{
							*(sp - 1) = reinterpret_cast<Oop>(Pointers.True);
							return sp - 1;
						}
					}
				}

				*(sp - 1) = reinterpret_cast<Oop>(Pointers.False);
				return sp - 1;
			}
		}
		else
			return nullptr;
	}
}

Oop* __fastcall Interpreter::primitiveAllMask(Oop* const sp, unsigned)
{
	Oop receiver = *(sp - 1);
	Oop arg = *sp;
	if (ObjectMemoryIsIntegerObject(arg))
	{
		// We can perform the comparisons without shifting away the SmallInteger bit since it always 1
		*(sp - 1) = reinterpret_cast<Oop>((receiver & arg) == arg ? Pointers.True : Pointers.False);
		return sp - 1;
	}
	else
	{
		LargeIntegerOTE* oteArg = reinterpret_cast<LargeIntegerOTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			// If receiver -ve allMask could be true, depending on comparison with bottom limb
			// If receiver +ve, can never be true
			SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
			uint32_t argLow = oteArg->m_location->m_digits[0];
			*(sp - 1) = reinterpret_cast<Oop>(r < 0 && ((static_cast<uint32_t>(r) & argLow) == argLow) ? Pointers.True : Pointers.False);
			return sp - 1;
		}
		else
			return nullptr;
	}
}

Oop* __fastcall Interpreter::primitiveLowBit(Oop* const sp, unsigned)
{
	SMALLINTEGER value = *(sp) ^ 1;
	unsigned long index;
	_BitScanForward(&index, value);
	*sp = ObjectMemoryIntegerObjectOf(index);
	return sp;
}

Oop* __fastcall Interpreter::primitiveHighBit(Oop* const sp, unsigned)
{
	Oop oopInteger = *sp;
	if (ObjectMemoryIsIntegerObject(oopInteger))
	{
		SMALLINTEGER value = static_cast<SMALLINTEGER>(oopInteger);
		if (value >= 0)
		{
			unsigned long index;
			_BitScanReverse(&index, value);
			*sp = ObjectMemoryIntegerObjectOf(index);
			return sp;
		}
		else
			return nullptr;
	}
	else
	{
		// Note that Integers are always normalized. This means that zero cannot be a LargeInteger, i.e.
		// the bottom limb can never be zero, and the result of this primitive cannot be zero. 
		// Also there can be at most one leading zero limb (e.g. for 2**63)

		LargeIntegerOTE* oteReceiver = reinterpret_cast<LargeIntegerOTE*>(*sp);
		LargeInteger* liReceiver = oteReceiver->m_location;
		MWORD i = oteReceiver->getWordSize() - 1;
		uint32_t digit = liReceiver->m_digits[i];
		if (static_cast<int32_t>(digit) >= 0)
		{
			if (digit == 0)
			{
				digit = liReceiver->m_digits[--i];
			}

			unsigned long index;
			_BitScanReverse(&index, digit);
			index = i * 32 + index + 1;
			*sp = ObjectMemoryIntegerObjectOf(index);
			return sp;
		}
		else
			// Negative, undefined
			return nullptr;
	}
}

Oop* __fastcall Interpreter::primitiveAdd(Oop* const sp, unsigned)
{
	Oop receiver = *(sp - 1);
	Oop arg = *sp;
	if (!ObjectMemoryIsIntegerObject(arg))
	{
		LargeIntegerOTE* oteArg = reinterpret_cast<LargeIntegerOTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			LargeIntegerOTE* oteResult = LargeInteger::Add(oteArg, ObjectMemoryIntegerValueOf(receiver));
			// Normalize and return
			Oop oopResult = LargeInteger::NormalizeIntermediateResult(oteResult);
			*(sp - 1) = oopResult;
			ObjectMemory::AddToZct(oopResult);

			return sp - 1;
		}
		else if (oteArg->m_oteClass == Pointers.ClassFloat)
		{
			double floatA = reinterpret_cast<FloatOTE*>(oteArg)->m_location->m_fValue;
			double floatR = ObjectMemoryIntegerValueOf(receiver);
			FloatOTE* oteResult = Float::New(floatR + floatA);
			*(sp - 1) = reinterpret_cast<Oop>(oteResult);
			ObjectMemory::AddToZct(reinterpret_cast<OTE*>(oteResult));
			return sp - 1;
		}
		else
			return nullptr;
	}
	else
	{
		// We can do this more efficiently in assembler because we can access the overflow flag safely and efficiently
		// However this doesn't matter much because this code path is only ever used when #perform'ing SmallInteger>>+
		// Usually SmallInteger addition is performed inline in the bytecode interpreter

		SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
		SMALLINTEGER a = ObjectMemoryIntegerValueOf(arg);
		SMALLINTEGER result = r + a;

		if (ObjectMemoryIsIntegerValue(result))
		{
			*(sp - 1) = ObjectMemoryIntegerObjectOf(result);
			return sp - 1;
		}
		else
		{
			// Overflowed
			LargeIntegerOTE* oteResult = LargeInteger::liNewSigned(result);
			*(sp - 1) = reinterpret_cast<Oop>(oteResult);
			ObjectMemory::AddToZct(reinterpret_cast<OTE*>(oteResult));
			return sp - 1;
		}
	}
}

Oop* __fastcall Interpreter::primitiveSubtract(Oop* const sp, unsigned)
{
	Oop receiver = *(sp - 1);
	Oop arg = *sp;
	if (!ObjectMemoryIsIntegerObject(arg))
	{
		OTE* oteArg = reinterpret_cast<OTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			Oop oopNegatedArg = LargeInteger::Negate(reinterpret_cast<LargeIntegerOTE*>(oteArg));
			if (ObjectMemoryIsIntegerObject(oopNegatedArg))
			{
				SMALLINTEGER a = ObjectMemoryIntegerValueOf(oopNegatedArg);
				SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
				SMALLINTEGER result = a + r;

				if (ObjectMemoryIsIntegerValue(result))
				{
					*(sp - 1) = ObjectMemoryIntegerObjectOf(result);
					return sp - 1;
				}
				else
				{
					// Overflowed
					LargeIntegerOTE* oteResult = LargeInteger::liNewSigned(result);
					*(sp - 1) = reinterpret_cast<Oop>(oteResult);
					ObjectMemory::AddToZct(reinterpret_cast<OTE*>(oteResult));
					return sp - 1;
				}
			}
			else
			{
				LargeIntegerOTE* oteNegatedArg = reinterpret_cast<LargeIntegerOTE*>(oopNegatedArg);
				LargeIntegerOTE* oteResult = LargeInteger::Add(oteNegatedArg, ObjectMemoryIntegerValueOf(receiver));
				LargeInteger::DeallocateIntermediateResult(oteNegatedArg);
				// Normalize and return
				Oop oopResult = LargeInteger::NormalizeIntermediateResult(oteResult);
				*(sp - 1) = oopResult;
				ObjectMemory::AddToZct(oopResult);
				return sp - 1;
			}
		}
		else if (oteArg->m_oteClass == Pointers.ClassFloat)
		{
			double floatA = reinterpret_cast<FloatOTE*>(oteArg)->m_location->m_fValue;
			double floatR = ObjectMemoryIntegerValueOf(receiver);
			FloatOTE* oteResult = Float::New(floatR - floatA);
			*(sp - 1) = reinterpret_cast<Oop>(oteResult);
			ObjectMemory::AddToZct(reinterpret_cast<OTE*>(oteResult));
			return sp - 1;
		}
		else
			return nullptr;
	}
	else
	{
		// We can do this more efficiently in assembler because we can access the overflow flag safely and efficiently
		// However this doesn't matter much because this code path is only ever used when #perform'ing SmallInteger>>+
		// Usually SmallInteger addition is performed inline in the bytecode interpreter

		SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
		SMALLINTEGER a = ObjectMemoryIntegerValueOf(arg);
		SMALLINTEGER result = r - a;

		if (ObjectMemoryIsIntegerValue(result))
		{
			*(sp - 1) = ObjectMemoryIntegerObjectOf(result);
			return sp - 1;
		}
		else
		{
			// Overflowed
			LargeIntegerOTE* oteResult = LargeInteger::liNewSigned(result);
			*(sp - 1) = reinterpret_cast<Oop>(oteResult);
			ObjectMemory::AddToZct(reinterpret_cast<OTE*>(oteResult));
			return sp - 1;
		}
	}
}

Oop* __fastcall Interpreter::primitiveMultiply(Oop* const sp, unsigned)
{
	Oop receiver = *(sp - 1);
	Oop arg = *sp;
	if (!ObjectMemoryIsIntegerObject(arg))
	{
		LargeIntegerOTE* oteArg = reinterpret_cast<LargeIntegerOTE*>(arg);
		if (oteArg->m_oteClass == Pointers.ClassLargeInteger)
		{
			SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
			if (r != 0)
			{
				Oop oopResult = LargeInteger::Mul(oteArg, r);
				// Normalize and return
				*(sp - 1) = normalizeIntermediateResult(oopResult);
				ObjectMemory::AddToZct(oopResult);
				return sp - 1;
			}
			else
			{
				*(sp - 1) = ZeroPointer;
				return sp - 1;
			}
		}
		else if (oteArg->m_oteClass == Pointers.ClassFloat)
		{
			double floatA = reinterpret_cast<FloatOTE*>(oteArg)->m_location->m_fValue;
			double floatR = ObjectMemoryIntegerValueOf(receiver);
			FloatOTE* oteResult = Float::New(floatR * floatA);
			*(sp - 1) = reinterpret_cast<Oop>(oteResult);
			ObjectMemory::AddToZct(reinterpret_cast<OTE*>(oteResult));
			return sp - 1;
		}
		else
			return nullptr;
	}
	else
	{
		// We can do this more efficiently in assembler because we can access the overflow flag safely and efficiently
		// However this doesn't matter much because this code path is only ever used when #perform'ing SmallInteger>>*
		// Usually SmallInteger multiplication is performed inline in the bytecode interpreter

		SMALLINTEGER r = ObjectMemoryIntegerValueOf(receiver);
		SMALLINTEGER a = ObjectMemoryIntegerValueOf(arg);
		int64_t result = __emul(r, a);

		Oop oopResult = Integer::NewSigned64(result);
		*(sp - 1) = oopResult;
		ObjectMemory::AddToZct(oopResult);
		return sp - 1;
	}
}

Oop* __fastcall Interpreter::primitiveSmallIntegerPrintString(Oop* const sp, unsigned)
{
	Oop integerPointer = *sp;

#ifdef _WIN64
	char buffer[32];
	errno_t err = _i64toa_s(ObjectMemoryIntegerValueOf(integerPointer), buffer, sizeof(buffer), 10);
#else
	char buffer[16];
	errno_t err = _itoa_s(ObjectMemoryIntegerValueOf(integerPointer), buffer, sizeof(buffer), 10);
#endif
	if (err == 0)
	{
		auto oteResult = AnsiString::New(buffer);
		*sp = reinterpret_cast<Oop>(oteResult);
		ObjectMemory::AddToZct((OTE*)oteResult);
		return sp;
	}
	else
		return primitiveFailure(0);
}

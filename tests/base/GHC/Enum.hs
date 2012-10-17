{-# LANGUAGE MagicHash #-}
{-# OPTIONS_GHC -XNoImplicitPrelude #-}
{-# OPTIONS_HADDOCK hide #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  GHC.Enum
-- Copyright   :  (c) The University of Glasgow, 1992-2002
-- License     :  see libraries/base/LICENSE
-- 
-- Maintainer  :  cvs-ghc@haskell.org
-- Stability   :  internal
-- Portability :  non-portable (GHC extensions)
--
-- The 'Enum' and 'Bounded' classes.
-- 
-----------------------------------------------------------------------------

-- #hide
module GHC.Enum(
        Bounded(..), Enum(..),
        boundedEnumFrom, boundedEnumFromThen,

        -- Instances for Bounded and Enum: (), Char, Int

   ) where

import GHC.Base
import Data.Tuple       ()              -- for dependencies
default ()              -- Double isn't available yet


class  Bounded a  where
    minBound, maxBound :: a

class  Enum a   where
    -- | the successor of a value.  For numeric types, 'succ' adds 1.
    succ                :: a -> a
    -- | the predecessor of a value.  For numeric types, 'pred' subtracts 1.
    pred                :: a -> a
    -- | Convert from an 'Int'.
    toEnum              :: Int -> a
    -- | Convert to an 'Int'.
    -- It is implementation-dependent what 'fromEnum' returns when
    -- applied to a value that is too large to fit in an 'Int'.
    fromEnum            :: a -> Int

    -- | Used in Haskell's translation of @[n..]@.
    enumFrom            :: a -> [a]
    -- | Used in Haskell's translation of @[n,n'..]@.
    enumFromThen        :: a -> a -> [a]
    -- | Used in Haskell's translation of @[n..m]@.
    enumFromTo          :: a -> a -> [a]
    -- | Used in Haskell's translation of @[n,n'..m]@.
    enumFromThenTo      :: a -> a -> a -> [a]

    succ                   = toEnum . (`plusInt` oneInt)  . fromEnum
    pred                   = toEnum . (`minusInt` oneInt) . fromEnum
    enumFrom x             = map toEnum [fromEnum x ..]
    enumFromThen x y       = map toEnum [fromEnum x, fromEnum y ..]
    enumFromTo x y         = map toEnum [fromEnum x .. fromEnum y]
    enumFromThenTo x1 x2 y = map toEnum [fromEnum x1, fromEnum x2 .. fromEnum y]

-- Default methods for bounded enumerations
boundedEnumFrom :: (Enum a, Bounded a) => a -> [a]
boundedEnumFrom n = map toEnum [fromEnum n .. fromEnum (maxBound `asTypeOf` n)]

boundedEnumFromThen :: (Enum a, Bounded a) => a -> a -> [a]
boundedEnumFromThen n1 n2 
  | i_n2 >= i_n1  = map toEnum [i_n1, i_n2 .. fromEnum (maxBound `asTypeOf` n1)]
  | otherwise     = map toEnum [i_n1, i_n2 .. fromEnum (minBound `asTypeOf` n1)]
  where
    i_n1 = fromEnum n1
    i_n2 = fromEnum n2

instance Bounded () where
    minBound = ()
    maxBound = ()

instance Enum () where
    succ _      = error "Prelude.Enum.().succ: bad argument"
    pred _      = error "Prelude.Enum.().pred: bad argument"

    toEnum x | x == zeroInt = ()
             | otherwise    = error "Prelude.Enum.().toEnum: bad argument"

    fromEnum () = zeroInt
    enumFrom ()         = [()]
    enumFromThen () ()  = let many = ():many in many
    enumFromTo () ()    = [()]
    enumFromThenTo () () () = let many = ():many in many

-- Report requires instances up to 15 (but Lambdachine currently only includes
-- instances up to 8)
instance (Bounded a, Bounded b) => Bounded (a,b) where
   minBound = (minBound, minBound)
   maxBound = (maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c) => Bounded (a,b,c) where
   minBound = (minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d) => Bounded (a,b,c,d) where
   minBound = (minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e) => Bounded (a,b,c,d,e) where
   minBound = (minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f)
        => Bounded (a,b,c,d,e,f) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g)
        => Bounded (a,b,c,d,e,f,g) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h)
        => Bounded (a,b,c,d,e,f,g,h) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound)

{-
instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i)
        => Bounded (a,b,c,d,e,f,g,h,i) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i, Bounded j)
        => Bounded (a,b,c,d,e,f,g,h,i,j) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i, Bounded j, Bounded k)
        => Bounded (a,b,c,d,e,f,g,h,i,j,k) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i, Bounded j, Bounded k, Bounded l)
        => Bounded (a,b,c,d,e,f,g,h,i,j,k,l) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i, Bounded j, Bounded k, Bounded l, Bounded m)
        => Bounded (a,b,c,d,e,f,g,h,i,j,k,l,m) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound, maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i, Bounded j, Bounded k, Bounded l, Bounded m, Bounded n)
        => Bounded (a,b,c,d,e,f,g,h,i,j,k,l,m,n) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound, minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound, maxBound, maxBound, maxBound, maxBound, maxBound)

instance (Bounded a, Bounded b, Bounded c, Bounded d, Bounded e, Bounded f, Bounded g,
          Bounded h, Bounded i, Bounded j, Bounded k, Bounded l, Bounded m, Bounded n, Bounded o)
        => Bounded (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o) where
   minBound = (minBound, minBound, minBound, minBound, minBound, minBound, minBound, minBound,
               minBound, minBound, minBound, minBound, minBound, minBound, minBound)
   maxBound = (maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound,
               maxBound, maxBound, maxBound, maxBound, maxBound, maxBound, maxBound)
-}

instance Bounded Bool where
  minBound = False
  maxBound = True

instance Enum Bool where
  succ False = True
  succ True  = error "Prelude.Enum.Bool.succ: bad argument"

  pred True  = False
  pred False  = error "Prelude.Enum.Bool.pred: bad argument"

  toEnum n | n == zeroInt = False
           | n == oneInt  = True
           | otherwise    = error "Prelude.Enum.Bool.toEnum: bad argument"

  fromEnum False = zeroInt
  fromEnum True  = oneInt

  -- Use defaults for the rest
  enumFrom     = boundedEnumFrom
  enumFromThen = boundedEnumFromThen

instance Bounded Ordering where
  minBound = LT
  maxBound = GT

instance Enum Ordering where
  succ LT = EQ
  succ EQ = GT
  succ GT = error "Prelude.Enum.Ordering.succ: bad argument"

  pred GT = EQ
  pred EQ = LT
  pred LT = error "Prelude.Enum.Ordering.pred: bad argument"

  toEnum n | n == zeroInt = LT
           | n == oneInt  = EQ
           | n == twoInt  = GT
  toEnum _ = error "Prelude.Enum.Ordering.toEnum: bad argument"

  fromEnum LT = zeroInt
  fromEnum EQ = oneInt
  fromEnum GT = twoInt

  -- Use defaults for the rest
  enumFrom     = boundedEnumFrom
  enumFromThen = boundedEnumFromThen

instance  Bounded Char  where
    minBound =  '\0'
    maxBound =  '\x10FFFF'

{-
instance  Enum Char  where
    succ (C# c#)
       | not (ord# c# ==# 0x10FFFF#) = C# (chr# (ord# c# +# 1#))
       | otherwise              = error ("Prelude.Enum.Char.succ: bad argument")
    pred (C# c#)
       | not (ord# c# ==# 0#)   = C# (chr# (ord# c# -# 1#))
       | otherwise              = error ("Prelude.Enum.Char.pred: bad argument")

    toEnum   = chr
    fromEnum = ord

    {-# INLINE enumFrom #-}
    enumFrom (C# x) = eftChar (ord# x) 0x10FFFF#
        -- Blarg: technically I guess enumFrom isn't strict!

    {-# INLINE enumFromTo #-}
    enumFromTo (C# x) (C# y) = eftChar (ord# x) (ord# y)
    
    {-# INLINE enumFromThen #-}
    enumFromThen (C# x1) (C# x2) = efdChar (ord# x1) (ord# x2)
    
    {-# INLINE enumFromThenTo #-}
    enumFromThenTo (C# x1) (C# x2) (C# y) = efdtChar (ord# x1) (ord# x2) (ord# y)
-}

instance  Bounded Int where
    minBound =  minInt
    maxBound =  maxInt

instance  Enum Int  where
    succ x  
       | x == maxBound  = error "Prelude.Enum.succ{Int}: tried to take `succ' of maxBound"
       | otherwise      = x `plusInt` oneInt
    pred x
       | x == minBound  = error "Prelude.Enum.pred{Int}: tried to take `pred' of minBound"
       | otherwise      = x `minusInt` oneInt

    toEnum   x = x
    fromEnum x = x

    {-# INLINE enumFrom #-}
    enumFrom (I# x) = eftInt x maxInt#
        where !(I# maxInt#) = maxInt
        -- Blarg: technically I guess enumFrom isn't strict!

    {-# INLINE enumFromTo #-}
    enumFromTo (I# x) (I# y) = eftInt x y

    {-# INLINE enumFromThen #-}
    enumFromThen (I# x1) (I# x2) = efdInt x1 x2

    {-# INLINE enumFromThenTo #-}
    enumFromThenTo (I# x1) (I# x2) (I# y) = efdtInt x1 x2 y

eftInt :: Int# -> Int# -> [Int]
-- [x1..x2]
eftInt x0 y | x0 ># y    = []
            | otherwise = go x0
               where
                 go x = I# x : if x ==# y then [] else go (x +# 1#)

{-# INLINE [0] eftIntFB #-}
eftIntFB :: (Int -> r -> r) -> r -> Int# -> Int# -> r
eftIntFB c n x0 y | x0 ># y    = n        
                  | otherwise = go x0
                 where
                   go x = I# x `c` if x ==# y then n else go (x +# 1#)

efdInt :: Int# -> Int# -> [Int]
-- [x1,x2..maxInt]
efdInt x1 x2 
 | x2 >=# x1 = case maxInt of I# y -> efdtIntUp x1 x2 y
 | otherwise = case minInt of I# y -> efdtIntDn x1 x2 y

efdtInt :: Int# -> Int# -> Int# -> [Int]
-- [x1,x2..y]
efdtInt x1 x2 y
 | x2 >=# x1 = efdtIntUp x1 x2 y
 | otherwise = efdtIntDn x1 x2 y

{-# INLINE [0] efdtIntFB #-}
efdtIntFB :: (Int -> r -> r) -> r -> Int# -> Int# -> Int# -> r
efdtIntFB c n x1 x2 y
 | x2 >=# x1  = efdtIntUpFB c n x1 x2 y
 | otherwise  = efdtIntDnFB c n x1 x2 y

-- Requires x2 >= x1
efdtIntUp :: Int# -> Int# -> Int# -> [Int]
efdtIntUp x1 x2 y    -- Be careful about overflow!
 | y <# x2   = if y <# x1 then [] else [I# x1]
 | otherwise = -- Common case: x1 <= x2 <= y
               let !delta = x2 -# x1 -- >= 0
                   !y' = y -# delta  -- x1 <= y' <= y; hence y' is representable

                   -- Invariant: x <= y
                   -- Note that: z <= y' => z + delta won't overflow
                   -- so we are guaranteed not to overflow if/when we recurse
                   go_up x | x ># y'  = [I# x]
                           | otherwise = I# x : go_up (x +# delta)
               in I# x1 : go_up x2

-- Requires x2 >= x1
efdtIntUpFB :: (Int -> r -> r) -> r -> Int# -> Int# -> Int# -> r
efdtIntUpFB c n x1 x2 y    -- Be careful about overflow!
 | y <# x2   = if y <# x1 then n else I# x1 `c` n
 | otherwise = -- Common case: x1 <= x2 <= y
               let !delta = x2 -# x1 -- >= 0
                   !y' = y -# delta  -- x1 <= y' <= y; hence y' is representable

                   -- Invariant: x <= y
                   -- Note that: z <= y' => z + delta won't overflow
                   -- so we are guaranteed not to overflow if/when we recurse
                   go_up x | x ># y'   = I# x `c` n
                           | otherwise = I# x `c` go_up (x +# delta)
               in I# x1 `c` go_up x2

-- Requires x2 <= x1
efdtIntDn :: Int# -> Int# -> Int# -> [Int]
efdtIntDn x1 x2 y    -- Be careful about underflow!
 | y ># x2   = if y ># x1 then [] else [I# x1]
 | otherwise = -- Common case: x1 >= x2 >= y
               let !delta = x2 -# x1 -- <= 0
                   !y' = y -# delta  -- y <= y' <= x1; hence y' is representable

                   -- Invariant: x >= y
                   -- Note that: z >= y' => z + delta won't underflow
                   -- so we are guaranteed not to underflow if/when we recurse
                   go_dn x | x <# y'  = [I# x]
                           | otherwise = I# x : go_dn (x +# delta)
   in I# x1 : go_dn x2

-- Requires x2 <= x1
efdtIntDnFB :: (Int -> r -> r) -> r -> Int# -> Int# -> Int# -> r
efdtIntDnFB c n x1 x2 y    -- Be careful about underflow!
 | y ># x2 = if y ># x1 then n else I# x1 `c` n
 | otherwise = -- Common case: x1 >= x2 >= y
               let !delta = x2 -# x1 -- <= 0
                   !y' = y -# delta  -- y <= y' <= x1; hence y' is representable

                   -- Invariant: x >= y
                   -- Note that: z >= y' => z + delta won't underflow
                   -- so we are guaranteed not to underflow if/when we recurse
                   go_dn x | x <# y'   = I# x `c` n
                           | otherwise = I# x `c` go_dn (x +# delta)
               in I# x1 `c` go_dn x2


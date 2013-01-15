{-# OPTIONS_GHC -XNoImplicitPrelude #-}
module GHC.Err( error ) where

-- The type signature for 'error' is a gross hack.
-- First, we can't give an accurate type for error, because it mentions 
-- an open type variable.
-- Second, we can't even say error :: [Char] -> a, because Char is defined
-- in GHC.Base, and that would make Err.lhs-boot mutually recursive 
-- with GHC.Base.
-- Fortunately it doesn't matter what type we give here because the 
-- compiler will use its wired-in version.  But we have
-- to mention 'error' so that it gets exported from this .hi-boot
-- file.
error    :: a

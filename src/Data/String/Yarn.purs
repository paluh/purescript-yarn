module Data.String.Yarn
  ( class IsString
  , fromString
  , TagString
  , runTag
  , tag
  , fromChars
  , lines
  , unlines
  , words
  , unwords
  , substitute
  , substituteMany
  , capitalize
  , capWords
  , rightpad, rightpadBy
  , leftpad, leftpadBy
  , reverse
  , replicate
  , charMap
  , charTraverse
  , charFold
  , rot13
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Char (toCharCode, fromCharCode)
import Data.String (singleton, split, joinWith, replace, uncons, toUpper, toCharArray, fromCharArray)
import Data.Traversable (class Foldable, foldMap, traverse, foldl)
import Data.Monoid (class Monoid)
import Data.Generic (class Generic)
import Data.Tuple (Tuple(..))

class IsString a where
  fromString :: String -> a

instance isStringString :: IsString String where
  fromString = id

instance isStringArrayChar :: IsString (Array Char) where
  fromString = toCharArray

-- | A generic `String` tagged by a row of data types
newtype TagString (a :: # *) = Tag String

derive instance eqTagString :: Eq (TagString a)

derive instance ordTagString :: Ord (TagString a)

derive instance genericTagString :: Generic (TagString a)

instance showTagString :: Show (TagString a) where
  show (Tag s) = "Tag " <> show s

instance semigroupTagString :: Semigroup (TagString a) where
  append (Tag s) (Tag p) = Tag (s <> p)

instance monoidTagString :: Monoid (TagString a) where
  mempty = Tag ""

-- | Turn a tagged `String` into a `String`
runTag :: forall a. TagString a -> String
runTag (Tag s) = s

-- | Turn a `String` into a tagged `String`
tag :: forall a. String -> TagString a
tag = Tag

-- | Turn a `Foldable` container of `Char`s to a `String`
fromChars :: forall f. Foldable f => f Char -> String
fromChars = foldMap singleton

-- | Split a `String` by its newlines
lines :: String -> Array String
lines = split "\n"

-- | Join an `Array` of `String`s with newlines
unlines :: Array String -> String
unlines = joinWith "\n"

-- | Split a `String` by its spaces
words :: String -> Array String
words = split " "

-- | Join an `Array` of `String`s with spaces
unwords :: Array String -> String
unwords = joinWith " "

until :: forall a. (a -> a -> Boolean) -> (a -> a) -> a -> a
until p f x | p x (f x) = x
until p f x = until p f (f x)

-- | Like `replace` but acts globally
substitute :: String -> String -> String -> String
substitute old new = until eq (replace old new)

-- | Replace many substitutions given some association list
substituteMany :: forall f. Foldable f => f (Tuple String String) -> String -> String
substituteMany = flip (foldl f)
  where
    f str (Tuple old new) = substitute old new str

-- | Capitalize the first `Char` in a `String`
capitalize :: String -> String
capitalize str = case uncons str of
  Just {head, tail} -> toUpper (singleton head) <> tail
  _ -> str

-- | Capitalize the first `Char` in each word of a given `String`
capWords :: String -> String
capWords = unwords <<< map capitalize <<< words

-- | Append a space to the right of a `String`
rightpad :: String -> String
rightpad = (_ <> " ")

-- | Append a given number of spaces to the right of a `String`
rightpadBy :: Int -> String -> String
rightpadBy n = (_ <> replicate n ' ')

-- | Append a space to the left of a `String`
leftpad :: String -> String
leftpad = append " "

-- | Append a given number of spaces to the left of a `String`
leftpadBy :: Int -> String -> String
leftpadBy n = append (replicate n ' ')

-- | Reverse a `String`, may give funky results with unicode
reverse :: String -> String
reverse = fromCharArray <<< Array.reverse <<< toCharArray

-- | Replicate a `Char` a given number of times
replicate :: Int -> Char -> String
replicate = replicate' ""
  where
    replicate' acc 0 _ = acc
    replicate' acc n c = replicate' (singleton c <> acc) (n - 1) c

-- | Transform a function on `Char`s to a function on `String`s
charMap :: (Char -> Char) -> String -> String
charMap f = fromCharArray <<< map f <<< toCharArray

-- | Fold over a `String` with a function that takes an accumulator `String` and next `Char` as input
charFold :: (String -> Char -> String) -> String -> String -> String
charFold f z str = case uncons str of
  Just {head, tail} -> charFold f (f z head) tail
  _ -> z

-- | Transform a Kleisli arrow on `Char`s to one on `String`s
charTraverse :: forall m. Applicative m => (Char -> m Char) -> String -> m String
charTraverse f str = fromCharArray <$> traverse f (toCharArray str)

-- | Cresbezf n ebg13 fhofgvghgvba ba n `Fgevat`
rot13 :: String -> String
rot13 = charMap rotate
  where
    rotate :: Char -> Char
    rotate c
      | toCharCode c <= 90 && toCharCode c >= 65 = fromCharCode $ 65 + ((toCharCode c - 52) `mod` 26)
      | toCharCode c <= 122 && toCharCode c >= 97 = fromCharCode $ 97 + ((toCharCode c - 84) `mod` 26)
      | otherwise = c

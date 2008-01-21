
module Text.HTML.TagSoup.Tree (
    TagTree(..), tagTree, flattenTree,
    transformTags, universeTags
    ) where

import Text.HTML.TagSoup.Type


data TagTree = TagBranch String [Attribute] [TagTree]
             | TagLeaf Tag
             deriving Show



-- | Convert a list of tags into a tree. This version is not lazy at
--   all, that is saved for version 2.
tagTree :: [Tag] -> [TagTree]
tagTree = g
    where
        g :: [Tag] -> [TagTree]
        g [] = []
        g xs = a ++ map TagLeaf (take 1 b) ++ g (drop 1 b)
            where (a,b) = f xs

        -- the second tuple is either null or starts with a close
        f :: [Tag] -> ([TagTree],[Tag])
        f (TagOpen name atts:xs) =
            case f xs of
                (inner,[]) -> (TagLeaf (TagOpen name atts):inner, [])
                (inner,TagClose x:xs)
                    | x == name -> let (a,b) = f xs in (TagBranch name atts inner:a, b)
                    | otherwise -> (TagLeaf (TagOpen name atts):inner, TagClose x:xs)

        f (TagClose x:xs) = ([], TagClose x:xs)
        f (x:xs) = (TagLeaf x:a,b)
            where (a,b) = f xs
        f [] = ([], [])


flattenTree :: [TagTree] -> [Tag]
flattenTree xs = concatMap f xs
    where
        f (TagBranch name atts inner) =
            TagOpen name atts : flattenTree inner ++ [TagClose name]
        f (TagLeaf x) = [x]


universeTags :: [TagTree] -> [TagTree]
universeTags = concatMap f
    where
        f t@(TagBranch _ _ inner) = t : universeTags inner
        f x = [x]


transformTags :: (TagTree -> [TagTree]) -> [TagTree] -> [TagTree]
transformTags act = concatMap f
    where
        f (TagBranch a b inner) = act $ TagBranch a b (transformTags act inner)
        f x = act x
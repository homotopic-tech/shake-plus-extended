# Shake+ Extended - Experimental Mechanisms For Shake

This library extends
[shake-plus](https://hackage.haskell.org/package/shake-plus), which enriches
[shake](https://hackage.haskell.org/package/shake) with `ReaderT` and the
`Path` library. This extended ruleset introduces
[within](https://hackage.haskell.org/package/within), for better keeping track of
source and output directories, as well as batch loading mechanisms.

## Using Within

One common complaint about Shake is having to keep track of source and output
directories and translating `FilePath`s when using the input to an `Action`,
leading to lots of repetition of the form `(sourceFolder </>) . (-<.> ".ext") .
dropDirectory1` which is prone to breakage. Using `Path` helps this to some
degree, but in some cases is even more annoying because lots of `Path`
functions use `MonadThrow`, leading to lots of monadic steps inside an
`RAction`.

To alleviate this somewhat, we use `Within b (Path Rel File)` as a standard
pattern for representing a file within a directory. `Within` is a type
available in the [within](https://hackage.haskell.org/package/within) package
that is simply a newtype wrapper over an `Env` comonad with the environment
specialized to `Path b Dir`. We provide variants of the file operations and
rules that typically accept or return `Path`s or contain callbacks that expect
paths and change these to `Within` values. These functions are generally
suffixed `within`. Here is the variant of `getDirectoryFiles` that
produces `Within` values.

```{.haskell}
getDirectoryFilesWithin' :: MonadAction m => Within Rel [FilePattern] -> m [Within b (Path Rel File)]
```

You can convert to and from this within-style using `within` and `fromWithin`.

```{.haskell}
let x = $(mkRelFile "a.txt") `within` $(mkRelDir "foo") -- Within Rel (Path Rel File)
fromWithin x -- produces a `Path Rel File`
```

and you can assert that an existing path lies in a directory by using `asWithin`, which throws
if the directory is not a proper prefix of the `Path`.

```{.haskell}
$(mkRelFile "foo/a.txt") `asWithin` $(mkRelDir "foo") -- fine
$(mkRelFile "a.txt") `asWithin` $(mkRelDir "foo") -- throws error
```

Filerules such as `(%>)` have within-style variants that accept an ` (Path b
Dir) FilePattern` on the left and carry that env to the callback.

```{.haskell}
(%^>) :: (Partial, MonadReader r m, MonadRules m) => Within Rel FilePattern -> (Within Rel (Path Rel File) -> RAction r ()) -> m ()
```

You change the underlying filepath with `fmap` or `mapM`, whilst you can move
to a new parent directory by using `localDir`, or `localDirM` which is defined
in the `Within` library for when the map between parent directories may throw.
The `Within` library also contains more functions and instances for more
precise changes between output and source directories.

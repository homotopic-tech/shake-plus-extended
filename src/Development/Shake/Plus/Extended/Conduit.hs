{- |
   Module     : Shakebook.Conduit
   License    : MIT
   Stability  : experimental

Utilities for using conduit to store remote caches.
-}

module Development.Shake.Plus.Extended.Conduit (
  RemoteJSONLookup(..)
, addRemoteJSONOracleCache
) where

import           Data.Aeson
import           Data.Binary.Instances.Aeson ()
import           Development.Shake.Plus
import           Network.HTTP.Simple
import           RIO
import qualified RIO.Text                    as T

-- | Remote json lookup for an oracle, this should contain a URL as Text.
newtype RemoteJSONLookup = RemoteJSONLookup Text
  deriving (Show, Typeable, Eq)

type instance RuleResult RemoteJSONLookup = Value

deriving instance Hashable RemoteJSONLookup
deriving instance Binary RemoteJSONLookup
deriving instance NFData RemoteJSONLookup

-- | Adds an oracle cache for looking up json from a remote server.
addRemoteJSONOracleCache :: (MonadReader r m, MonadRules m) => m (RemoteJSONLookup -> RAction r Value)
addRemoteJSONOracleCache = addOracleCache $ \(RemoteJSONLookup x) -> do
  initReq <- parseRequest $ T.unpack x
  (y :: Response Value) <- httpJSON initReq
  return $ getResponseBody y


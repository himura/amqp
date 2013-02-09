{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Config where

import           Control.Applicative
import           Control.Exception   as E
import           Control.Monad
import           Data.Aeson
import qualified Data.ByteString     as S
import           Data.Maybe
import qualified Data.Yaml           as Yaml
import           Network.AMQP

instance FromJSON ConnectionOpts where
    parseJSON (Object o) = ConnectionOpts
        <$> mb connectionHost "host"
        <*> (fromMaybe (connectionPort def) <$> fmap fromInteger <$> o .:? "port")
        <*> mb connectionVHost "vhost"
        <*> mb connectionUser "user"
        <*> mb connectionPassword "password"
      where mb field name = fromMaybe (field def) <$> o .:? name
    parseJSON _ = mzero

loadConfig :: FromJSON a => FilePath -> IO a
loadConfig file = S.readFile file >>= \dat ->
    case Yaml.decodeEither dat of
        Right conf -> return conf
        Left err -> E.throw $ userError err


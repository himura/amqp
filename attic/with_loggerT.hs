{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE QuasiQuotes       #-}

import           Config
import           Control.Concurrent
import           Control.Monad
import           Data.IORef
import           Network.AMQP
import qualified Network.AMQP.Lifted as AMQPL
import           System.Environment
import Control.Monad.Logger
import Control.Monad.IO.Class
import qualified Data.Text as T
import Text.Shakespeare.Text

msgCount :: Int
msgCount = 10000

main :: IO ()
main = do
    (configFile:[]) <- getArgs
    conf <- loadConfig configFile
    withConnection conf $ \conn -> runStderrLoggingT $ do
        chan <- liftIO $ openChannel conn
        (q, _, _) <- liftIO $ declareQueue chan def { queueAutoDelete = True }
        $(logDebug) q
        liftIO $ bindQueue chan q "amq.topic" "publish.test"
        consumerId <- AMQPL.consumeMsgs chan q Ack $ \(msg, env) -> do
            $(logDebug) [st|Recieved message : #{show msg}|]
            liftIO $ ackEnv env
        $(logDebug) [st|start consumer : #{show consumerId}|]
        liftIO (getLine >> return ())

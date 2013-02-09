{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

import           Config
import           Control.Concurrent
import           Control.Monad
import           Data.IORef
import           Network.AMQP
import           System.Environment

msgCount :: Int
msgCount = 10000

main :: IO ()
main = do
    (configFile:[]) <- getArgs
    conf <- loadConfig configFile
    withConnection conf $ \conn -> do
        quit <- newEmptyMVar
        startConsume conn quit
        loopPublish conn
        takeMVar quit >> putStrLn "finished"

loopPublish :: Connection -> IO ()
loopPublish conn = do
    chan <- openChannel conn
    void $ replicateM msgCount $ publishMsg chan "amq.topic" "publish.test"
        newMsg { msgBody = "too_fast"
               , msgDeliveryMode = Just Persistent
               }

startConsume :: Connection -> MVar () -> IO ()
startConsume conn quit = do
    chan <- openChannel conn
    (q, _, _) <- declareQueue chan def { queueAutoDelete = True }
    bindQueue chan q "amq.topic" "publish.test"
    count <- newIORef (0::Int)
    consumerId <- consumeMsgs chan q Ack $ \(_, env) -> do
        n <- atomicModifyIORef count (\i -> let n = i + 1 in (n, n))
        when (n == msgCount) $ putMVar quit ()
        ackEnv env
    putStrLn $ "start consumer : " ++ show consumerId

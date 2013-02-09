{-# LANGUAGE BangPatterns      #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

import           Config
import           Control.Concurrent
import           Control.Monad
import           Criterion.Main
import qualified Data.ByteString.Lazy       as L
import qualified Data.ByteString.Lazy.Char8 as L8
import           Data.IORef
import           Network.AMQP

loopPublish :: Connection -> Int -> QueueName -> L.ByteString -> IO ()
loopPublish conn msgCount queueName body = do
    chan <- openChannel conn
    void $ replicateM msgCount $ publishMsg chan "" queueName
        newMsg { msgBody = body
               , msgDeliveryMode = Just Persistent
               }

startConsume :: Connection -> Int -> MVar () -> IO QueueName
startConsume conn msgCount quit = do
    chan <- openChannel conn
    (qn, _, _) <- declareQueue chan def { queueAutoDelete = True }
    count <- newIORef (0::Int)
    void $ consumeMsgs chan qn Ack $ \(_, env) -> do
        ackEnv env
        n <- atomicModifyIORef count (\i -> let !n = i + 1 in (n, n))
        when (n == msgCount) $ putMVar quit ()
    return qn

pubsubBS :: Connection -> Int -> L.ByteString -> IO ()
pubsubBS conn msgCount body = do
    quit <- newEmptyMVar
    qn <- startConsume conn msgCount quit
    loopPublish conn msgCount qn body
    takeMVar quit

msg100B :: L.ByteString
msg100B = L8.replicate 100 'x'

msg1kB :: L.ByteString
msg1kB = L8.replicate 1000 'x'

msg1MB :: L.ByteString
msg1MB = L8.replicate (1000*1000) 'x'

main :: IO ()
main = do
    conf <- loadConfig "config.yml"
    conn <- openConnection conf
    defaultMain
        [ bgroup "pub/sub static message"
            [ bench "small constant msg(100B) x 1000 msg" $ nfIO (pubsubBS conn 1000 msg100B)
            , bench "small constant msg(1kB) x 1000 msg" $ nfIO (pubsubBS conn 1000 msg1kB)
            , bench "small constant msg(1MB) x 1000 msg" $ nfIO (pubsubBS conn 1000 msg1MB)
            ]
        ]

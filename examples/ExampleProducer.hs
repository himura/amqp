{-# LANGUAGE OverloadedStrings #-}

import           Control.Monad
import qualified Data.ByteString.Lazy.Char8 as BL
import           Network.AMQP

main :: IO ()
main = do
    withConnection def $ \conn -> do
        chan <- openChannel conn

        --declare queues, exchanges and bindings
        void $ declareQueue chan newQueue {queueName = "myQueueDE"}
        void $ declareQueue chan newQueue {queueName = "myQueueEN"}

        declareExchange chan newExchange {exchangeName = "topicExchg", exchangeType = "topic"}
        bindQueue chan "myQueueDE" "topicExchg" "de.*"
        bindQueue chan "myQueueEN" "topicExchg" "en.*"

        --publish messages
        publishMsg chan "topicExchg" "de.hello"
            (newMsg {msgBody = (BL.pack "hallo welt"),
                     msgDeliveryMode = Just NonPersistent}
                    )
        publishMsg chan "topicExchg" "en.hello"
            (newMsg {msgBody = (BL.pack "hello world"),
                     msgDeliveryMode = Just NonPersistent}
                    )


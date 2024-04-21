use std::{borrow::Cow, future::Future};
use tokio::sync::mpsc;

/// Echoes messages back with the given prefix
pub fn echo_task(
    buffer: usize,
    prefix: Cow<'static, str>,
) -> (
    mpsc::Sender<Cow<'static, str>>,
    mpsc::Receiver<String>,
    impl Future<Output = ()>,
) {
    let (in_tx, mut in_rx) = mpsc::channel(buffer);
    let (out_tx, out_rx) = mpsc::channel(buffer);

    (in_tx, out_rx, async move {
        while let Some(msg) = in_rx.recv().await {
            let msg = format!("{prefix} {msg}");
            if out_tx.send(msg).await.is_err() {
                break;
            }
        }
    })
}

#[cfg(test)]
mod test {
    use super::echo_task;

    #[tokio::test]
    async fn smoke() {
        let (tx, mut rx, fut) = echo_task(10, "hello".into());

        tokio::spawn(fut);

        tx.send("world".into()).await.unwrap();
        assert_eq!("hello world", rx.recv().await.unwrap());

        tx.send("someone".into()).await.unwrap();
        assert_eq!("hello someone", rx.recv().await.unwrap());
    }
}

//! A cli which will echo every input argument to stdout

#[tokio::main]
async fn main() {
    let (tx, mut rx, fut) = my_common::echo_task(10, "echo".into());
    let args = std::env::args().skip(1).collect::<Vec<_>>();

    tokio::spawn(fut);
    tokio::spawn(async move {
        for arg in args {
            if tx.send(arg.into()).await.is_err() {
                eprintln!("channel was unexpectedly closed");
                break;
            }
        }
    });

    while let Some(msg) = rx.recv().await {
        println!("{msg}");
    }
}

use std::assert_eq;

use anyhow::Result;
use thirtyfour::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    let mut caps = DesiredCapabilities::firefox();
    caps.set_headless()?;
    let driver = WebDriver::new("http://localhost:4444", caps).await?;

    run(&driver).await?;

    driver.quit().await?;
    Ok(())
}

pub async fn run(driver: &WebDriver) -> Result<()> {
    driver.goto("localhost:8000").await?;

    driver
        .find(By::Id("username"))
        .await?
        .send_keys("John Doe")
        .await?;

    driver
        .find(By::Css("[type='submit']"))
        .await?
        .click()
        .await?;

    let returned_message = driver.query(By::Css("h1")).first().await?.text().await?;
    assert_eq!(returned_message, "Hello John Doe");

    driver.goto("localhost:8000").await?;
    let users = driver.query(By::Css("li")).all_from_selector().await?;
    assert_eq!(users.len(), 1, "There should be only a single user");
    assert_eq!(users[0].text().await?, "John Doe", "The test user's name should be in the home page");

    Ok(())
}

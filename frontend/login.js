console.log("hello!!")
fetch("https://d3ursguoush4q6.cloudfront.net/api/login", {
    mode: 'cors',
})
    .then(res => {
        if (res.status <= 400) {
            console.log(res.text())
            document.body.textContent = "Login completed"
        } else {
            throw new Error('Unauthorized')
        }
    })
    .catch(err => {
        document.body.textContent = "Login failed"
        console.error(err)
    })

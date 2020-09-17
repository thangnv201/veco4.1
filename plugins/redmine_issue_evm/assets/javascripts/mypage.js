//Mypage
$(document).ready(function () {
    let user = $('#loggedas').children().text()
    console.log("user", user)
    let url = window.location.href

    $.get(url + "/" + user + ".json", function (res) {
        let dataTable = res;
        if (dataTable.length > 0) {
            let index = 1;
            dataTable.forEach(data => {
                $("#my-page-statistic > tbody").append(getDataRow(data, index++));
            })
        } else {
            $("#my-page-statistic").hide();
        }

    })

    function getDataRow(data, index) {
        let id = data.project.id;
        let openTask = data.open_issues_by_tracker["Task(s)"] ? data.open_issues_by_tracker["Task(s)"] : 0;
        let totalTask = data.total_issues_by_tracker["Task(s)"] ? data.total_issues_by_tracker["Task(s)"] : 0;
        let closeTask = totalTask - openTask;

        let openMinestone = data.open_issues_by_tracker["Milestone(s)"] ? data.open_issues_by_tracker["Milestone(s)"] : 0;
        let totalMinestone = data.total_issues_by_tracker["Milestone(s)"] ? data.total_issues_by_tracker["Milestone(s)"] : 0;
        let closeMinestone = totalMinestone - openMinestone;

        let deadline = (data.deadline != null) ? data.deadline.split("-").reverse().join("-") : "N/A"
        let spi = "N/A";
        let ev = "N/A";
        let sv = "N/A";
        let classSPI = "";
        if (data.hasOwnProperty("spi")) {
            spi = parseFloat(data.spi.value) * 100;
            if(spi < 70){
                classSPI = "danger";
            }
            else if(spi >= 70 && spi < 90){
                classSPI = "warning";
            }
            else{
                classSPI = "success";
            }
            ev = data.ev.value;
            sv = (parseFloat(data.sv.value) < 0) ? parseFloat(data.sv.value) * -1 : parseFloat(data.sv.value);
        }
        let projectLink = url.replace("/my/page","") + "/projects/"+ data.project.identifier;

        let strHtml = "<tr id=`tr-${id}`>";
        strHtml += `<td style="text-align: center;">${index}</td>`;
        strHtml += `<td><a href="${projectLink}">${data.project.name}</a></td>`;
        strHtml += `<td style="text-align: center;">${deadline}</td>`;
        strHtml += `<td style="text-align: center;">${closeTask + "/" + totalTask}</td>`;
        strHtml += `<td style="text-align: center;">${closeMinestone + "/" + totalMinestone}</td>`;
        strHtml += `<td style="text-align: center;" class="${classSPI}">${spi}</td>`;
        strHtml += `<td style="text-align: center;">${ev}</td>`;
        strHtml += `<td style="text-align: center;">${sv}</td>`;
        strHtml += "</tr>";
        return strHtml;
    }
});

function myFunction(){
    var input = document.getElementById("myFile");
    var file = input.files[0];
    var reader = new FileReader();
    reader.onload = function(){
        //把文件内容保存到filecontent变量
        var filecontent = reader.result;
        //输出文件内容到<code>标签中
        // document.getElementById("fileContent").innerHTML = filecontent;
        onReadFileContent(filecontent);
    };
    reader.readAsText(file);
    
    
}


let installed_list = new Set();
let removed_list = new Set();
function set_installed(p) {
    installed_list.add(p);
    removed_list.delete(p);
}
function set_removed(p) {
    installed_list.delete(p);
    removed_list.add(p);
}

let obj_gByTime = {};  // 创建对象obj_gByTime
function onReadFileContent(filecontent) {
    let lines_arr = filecontent.split('\n');
    
    lines_arr = lines_arr.filter(function(line_t) {
        return ! line_t.startsWith("#");
    });
    
    //对于每一行，都按"|"分割
    let lines_cols_arr = [] ;
    for (let i = 0; i < lines_arr.length; i++) {
        var tmp_arr =  lines_arr[i].split('|') ;
        if ( tmp_arr.length <2)
            continue;
        lines_cols_arr.push(tmp_arr);
    } 
    
    
    let start_time;
    // 按顺序遍历每一行，按照第一列（时间）内容
    lines_cols_arr.forEach(function(line) {
        // console.log(line);
        // 如果遇到第二列是 install / remove 之外的，就更新时间
        const time = line[0].trim();
        const action = line[1].trim();
        
        if ( ! ['install', 'remove'].includes(action) ) {
            // console.log(action, "new time", time);
            start_time = time;
        } 
        
        // console.log(line);
        /*把lines里的各行分类到obj_gByTime里，键名为时间，键值为对象
         *    键值这个对象内容为'action':第二列内容,'c3':第3列内容, 'c4':第4列内容, 'c6':第6列内容, 'c7':第7列内容*/
        let lineObj = {
            'action': action.trim(),
            'c3': line[2]?.trim(),
            'c4': line[3]?.trim(),
            'c6': line[5]?.trim(),
            'c7': line[6]?.trim()
        };
        
        // console.log(time, lineObj);
        
        if (! Object.keys(obj_gByTime).includes(start_time) ) {
            // console.log("haha");
            obj_gByTime [start_time] = [];
        } 
        
        obj_gByTime[start_time] .push (lineObj); // 键名为时间
    });
    
    // 删掉不包含install或remove的时间（一般都是radd或rremove）
    for (time of Object.keys(obj_gByTime) ) {
        if (! obj_gByTime [time].some(obj => obj.action === 'install' || obj.action === 'remove') ) {
            delete obj_gByTime [time];
        }
    }
    
    
    for (time of Object.keys(obj_gByTime) ) {
        const session = obj_gByTime [time];
        
        var command;
        var arr_command;
        var program;
        var onSystemInstall = false;
        
        var session_install_list = { auto: [], manu: [], unsure: [], };
        var session_remove_list = [];
        
        if (session[0] ['action'] == 'command' ) {
            command = session[0]['c4'];
            arr_command = command.replaceAll("'", "").split(' ');
            
            if (session[0]['c3'] == "root@install")
                onSystemInstall = true;
            
            //判断program
            if ( (new RegExp("\\bzypper\\b")).test( command.split(' ')[0] ) ) {
                program = "zypper";
            } else {
                if ( (new RegExp("\\bsw_single\\b")).test( command ) )
                    program = "yast_sw_single"; 
                else if ( (new RegExp("\\bOneClickInstallWorker\\b")).test( command ) )
                    program = "OneClickInstallWorker";
                else
                    program = "system_installation";
            }
        }
        
        // 开始遍历这个session中的每个包操作 
        for (let i=1; i<session.length; ++i) {
            const line = session [i];
            const action = line['action'];
            
            if (action == 'install') {
                const p = line['c3'];
                
                set_installed(p);
                
                var install_type;
                
                // 判断install_type
                if (line['c6'] == "root@install" 
                    || (new RegExp("^[0-9]+:ruby\.ruby") ).test( line['c6'] )
                ) {
                    install_type = 'manu';
                } else {
                    if (program == 'zypper') {
                        var zypperAction;
                        for (var j=1; j<arr_command.length; j++) {
                            const arg = arr_command[j];
                            if (arg.startsWith('-') ) {
                                continue;
                            }else {
                                if ( ['in', 'install'].includes(arg) ) 
                                    zypperAction = 'install';
                                break;
                            } 
                                
                        } 
                            
                        if (zypperAction=='install') {
                            if (line['c6'].startsWith("root@"))
                                install_type='manu';
                            else
                                install_type='auto';
                        }else{
                            install_type='auto';
                        }
                    }else if (program == 'yast_sw_single') {
                        if (! line['c6'])
                            install_type='auto';
                        else
                            install_type='unsure';
                    }else if (program == 'system_installation') {
                        if (!install_type)
                            install_type = 'auto';
                    }
                }
                
                session_install_list[install_type].push(p);
            } 
            if (action == 'remove') {
                const p = line['c3']
                set_removed(p);
                session_remove_list.push(p);
            } 

        }
        
        session['program'] = program;
        session['command'] = command;
        
        for (let type of Object.keys(session_install_list)) {
            var type_list = session_install_list[type];
            type_list = type_list.sort();
        } 
        session['session_install_list'] = session_install_list;
        session['session_remove_list'] = session_remove_list.sort();
    }

        
    for (time of Object.keys(obj_gByTime) ) {
        const session = obj_gByTime [time];
        const program = session['program'];
        const command = session['command'];
        const session_install_list = session['session_install_list'];
        const session_remove_list = session['session_remove_list'];
        
        var html_manu = list_to_html(session_install_list['manu'] );
        var html_auto = list_to_html( session_install_list['auto']) ;
        var html_unsure = list_to_html( session_install_list['unsure']);
        var html_remove = list_to_html( session_remove_list);
        
        
        
        $$("#div_tables_cont").appendChild(htmlStr2dom(`
            <div> 
                <hr> 
                <details>
                <summary><b><code>${time} | ${program=="zypper"? command.replaceAll("'", "") : program}</code></b></summary>
                    <div>
                        <table>
                            <tr>
                                <th class="col_manu">User Install</th>
                                <th class="col_unsure">Install ?</th>
                                <th class="col_auto">Auto Install</th>
                                <th class="col_remove">Remove</th>
                            </tr>
                            <tr>
                                <td class="td_install col_manu">
                                    <div><code>${html_manu}</code></div>
                                </td>
                                <td class="td_install col_unsure">
                                    <div><code>${html_unsure}</code></div>
                                </td>
                                <td class="td_install col_auto">
                                    <div><code>${html_auto}</code></div>
                                </td>
                                <td class="td_remove col_remove">
                                    <div><code>${html_remove}</code></div>
                                </td>
                            </tr>
                        </table>
                    </div>
                </details> 
            </div>
        `)) 
    } 
    
    
    
    // var output = JSON.stringify(obj_gByTime,null, 4);
    // document.getElementById("fileContent").textContent = output;
    
    Array.from( document.getElementsByTagName('details') ) .forEach(  function (ele) {
        ele.open = true;
    });
}

function list_to_html(list) {
    var html='';
    
    
    for ( var ele of list) {
        var p_status_class='';
        if ( installed_list.has(ele) )
            p_status_class=' p_installed';
        else if (removed_list.has(ele))
            p_status_class=' p_removed';
        
        html += `<span class="span_p${p_status_class}">${ele}</span>&nbsp;\n`;
    }
    return html;
}
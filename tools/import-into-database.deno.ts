/// 输入 dump 文件夹路径
/// 例：（脚本所在文件夹）
/// deno run --unstable --allow-read --allow-net import-into-database.deno.ts ../fxc/安顺山庄2/data/dump

import { Client } from "https://deno.land/x/postgres/mod.ts";

function nowToDate(now: string): Date {
    const g = /(\d{4}-\d{2}-\d{2}).*(\d{2}:\d{2}:\d{2})/.exec(now)!;
    return new Date(`${g[1]}T${g[2]}+08:00`);
}

async function main() {
    const dumpDirPath = Deno.args[0];

    const client = new Client({
        user: 'postgres',
        hostname: 'pi',
        database: 'adnmb_qst_watcher',
        password: await Deno.readTextFile('./database-password.secret'),
    })
    await client.connect();
    await client.queryArray`SELECT set_config('fto.MIGRATING', ${true}::text, FALSE)`;
    await client.queryArray`SELECT set_config('fto.COMPLETION_REGISTRY_THREAD_ID', ${22762342}::text, FALSE)`;

    const thread = JSON.parse(await Deno.readTextFile(`${dumpDirPath}/thread.json`));
    console.log(thread.id)
    await client.queryArray`CALL record_thread(
        ${Number(thread.id)}, ${Number(thread.fid)},
        ${nowToDate(thread.now)}, ${thread.userid}, ${thread.content},
        ${thread.img}, ${thread.ext},
        ${thread.name === "无名氏" ? null : thread.name}, ${thread.email === "" ? null : thread.email}, ${thread.title === "无标题" ? null : thread.title},
        ${null},
        ${null}, ${null},
        ${true}
    )`;

    const pageFileNames = [];
    for await (const pageEntity of Deno.readDir(`${dumpDirPath}/pages`)) {
        pageFileNames.push(pageEntity.name);
    }
    pageFileNames.sort((a, b) => Number(/\d+/.exec(a)) - Number(/\d+/.exec(b)));
    let i = 0;
    for (const pageFileName of pageFileNames) {
        const responses = JSON.parse(await Deno.readTextFile(`${dumpDirPath}/pages/${pageFileName}`));
        for (const response of responses) {
            i++;
            if (i % 100 == 1) {
                console.log(i, pageFileName, response.id, response.now);
            }
            await client.queryArray`CALL record_response(
                ${Number(response.id)}, ${Number(thread.id)},
                ${nowToDate(response.now)}, ${response.userid}, ${response.content},
                ${response.img}, ${response.ext},
                ${response.name === "无名氏" ? null : response.name}, ${response.email === "" ? null : response.email}, ${response.title === "无标题" ? null : response.title},
                ${null},
                ${null},
                ${true}
            )`;
        }
    }

    await client.end();
}

await main();

def main():
    print("請輸入兩次 Node 名稱（NodeA 或 NodeB）以確認一致性")
    valid_nodes = ["NodeA", "NodeB"]
    output_file = "/TestAP/PPID/node_selected.txt"

    while True:
        input1 = input("第一次輸入: ").strip()
        input2 = input("第二次輸入: ").strip()

        if input1 not in valid_nodes or input2 not in valid_nodes:
            print("❌ 輸入錯誤：只能是 NodeA 或 NodeB")
            input("請按 Enter 鍵重新輸入...")
            continue  # 重新開始迴圈，要求使用者重新輸入

        if input1 == input2:
            with open(output_file, "w", encoding="utf-8") as f:
                f.write(input1 + "\n")
            print(f"✅ 已確認並寫入檔案：{input1}")
            break  # 輸入有效，跳出迴圈
        else:
            print("❌ 輸入不一致，請重新輸入...")
            input("請按 Enter 鍵重新輸入...")
            continue  # 重新開始迴圈，要求使用者重新輸入

if __name__ == "__main__":
    main()

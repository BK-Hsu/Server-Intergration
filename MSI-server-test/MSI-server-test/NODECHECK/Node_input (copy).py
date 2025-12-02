def main():
    print("請輸入兩次 Node 名稱（NodeA 或 NodeB）以確認一致性")

    input1 = input("第一次輸入: ").strip()
    input2 = input("第二次輸入: ").strip()

    valid_nodes = ["NodeA", "NodeB"]
    output_file = "/TestAP/PPID/node_selected.txt"

    if input1 not in valid_nodes or input2 not in valid_nodes:
        print("❌ 輸入錯誤：只能是 NodeA 或 NodeB")
        return

    if input1 == input2:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(input1 + "\n")
        print(f"✅ 已確認並寫入檔案：{input1}")
    else:
        print("❌ 輸入不一致，請重新執行")

if __name__ == "__main__":
    main()
